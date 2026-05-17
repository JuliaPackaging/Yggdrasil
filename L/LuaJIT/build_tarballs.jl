using BinaryBuilder

name = "LuaJIT"
# LuaJIT has effectively moved to a "rolling release" model where users are expected
# to track the `v2.1` branch of the Git repository rather than rely on formal releases.
# Translate that to Yggdrasil versioning by using the date of the pinned commit as the
# patch number with the upstream version as the major and minor parts.
version = v"2.1.20260330"

# Upstream version, i.e. what the `VERSION` variable in the Makefile expands to.
# Upstream's src/host/genversion.lua derives the trailing component from
# `git show -s --format=%ct` of the pinned commit (Unix epoch), so the binary name
# and SONAMEs end in "2.1.<unix-timestamp>".
upstream_version = v"2.1.1774896198"
# The Lua ABI version, i.e. the Lua version targeted for compatibility by this version
# of LuaJIT. Taken from `ABIVER` in the Makefile.
abi_version = "5.1"

sources = [
    GitSource("https://github.com/LuaJIT/LuaJIT.git",
              "18b087cd2cd4ddc4a79782bf155383a689d5093d"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/LuaJIT*

for file in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${file}
done

# LuaJIT requires the buildvm/minilua host tools to share pointer size with the
# target. BB's x86_64-linux-musl rootfs has no 32-bit multilib, so `HOSTCC -m32`
# fails to link (no 32-bit libc/libgcc). Workaround for 32-bit *Linux* targets:
# use the target cross-compiler statically; the static i686 binary runs natively
# on the x86_64 build host via kernel ia32 emulation, no ldso needed.
HOST_C="${HOSTCC} -m${nbits}"
if [[ "${nbits}" == "32" && ${target} == *-linux-* ]]; then
    HOST_C="${CC} -static"
fi

FLAGS=(
    PREFIX="${prefix}"
    TARGET_CC="${CC}"
    TARGET_CFLAGS="-I${includedir}"
    TARGET_LDFLAGS="-L${libdir}"
    HOST_CC="${HOST_C}"
    HOST_SYS="BinaryBuilder"
)

if [[ ${target} == *-apple-* ]]; then
    FLAGS+=(TARGET_SYS="Darwin")
elif [[ ${target} == *-freebsd* ]]; then
    FLAGS+=(TARGET_SYS="FreeBSD")
elif [[ ${target} == *-mingw* ]]; then
    FLAGS+=(TARGET_SYS="Windows")
else
    FLAGS+=(TARGET_SYS="Linux")
fi

make -j${nproc} amalg "${FLAGS[@]}"
make install "${FLAGS[@]}"

# LuaJIT's Makefile install rules use Linux SO conventions even for TARGET_SYS=Windows
# (DLL installed under lib/ as libluajit-5.1.so.X.Y.Z; exe installed without .exe), so
# relocate to Windows conventions: lua51.dll -> bin/, .exe extension on the executable,
# import lib named libluajit-5.1.dll.a.
if [[ ${target} == *-mingw* ]]; then
    # On Windows ${libdir} == ${bindir}, but LuaJIT's `make install PREFIX=…` writes to
    # ${prefix}/lib regardless, so refer to that absolute path explicitly here.
    rm -f ${prefix}/lib/libluajit-5.1.so ${prefix}/lib/libluajit-5.1.so.2
    mv ${prefix}/lib/libluajit-5.1.so.2.1.0 ${bindir}/lua51.dll
    mv ${prefix}/lib/libluajit-5.1.a ${prefix}/lib/libluajit-5.1.dll.a
    for f in ${bindir}/luajit-*; do
        [[ ${f} == *.exe ]] && continue
        mv ${f} ${f}.exe
    done
fi

install_license ${WORKSPACE}/srcdir/LuaJIT/COPYRIGHT
"""

platforms = filter(supported_platforms()) do p
    # LuaJIT 2.1 has no upstream support for ppc64le or riscv64
    arch(p) in ("powerpc64le", "riscv64") && return false
    # 32-bit ARM cross would need a 32-bit-host-runnable buildvm/minilua. The target
    # cross-compiler produces ARM ELF that can't exec on BB's x86_64-linux-musl host
    # without qemu-user/binfmt_misc (neither is installed in the BB sandbox), and
    # `HOSTCC -m32` fails to link because the rootfs ships no 32-bit multilib.
    arch(p) in ("armv6l", "armv7l") && return false
    # 32-bit Windows MinGW has the same host-pointer-size problem with no escape
    # hatch: the target cross-compiler emits PE/COFF (won't run on Linux), and
    # `HOSTCC -m32` still hits the missing-multilib link failure.
    Sys.iswindows(p) && nbits(p) == 32 && return false
    return true
end

products = [
    ExecutableProduct("luajit-$(upstream_version)", :luajit),
    # On Linux, the SONAME is "libluajit-5.1.so", which BB parses as libname
    # "libluajit-5.1". On macOS, files like "libluajit-5.1.2.dylib" parse as libname
    # "libluajit-5" (BB strips the trailing numeric components as a version), so we
    # list both. The 5-component INSTALL_DYLIBNAME ("libluajit-5.1.2.1.0.dylib") makes
    # BB's parser throw on VersionNumber("1.2.1.0"); valid_dl_path swallows the
    # exception so the real file is silently skipped, and only the symlinks
    # libluajit-5.1.dylib / libluajit-5.1.2.dylib are matched.
    LibraryProduct(["libluajit-$(abi_version)",
                    "libluajit-$(split(abi_version, '.')[1])",
                    "lua" * replace(abi_version, "." => "")],
                   :libluajit),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
