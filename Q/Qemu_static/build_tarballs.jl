# statically-compiled QEMU binaries, suitable for e.g. use within a container.

using BinaryBuilder, BinaryBuilderBase, Pkg

name = "Qemu_static"
version = v"7.1.0"

# Collection of sources required to build libffi
sources = [
    ArchiveSource("https://download.qemu.org/qemu-$(version).tar.xz",
                  "a0634e536bded57cf38ec8a751adb124b89c776fe0846f21ab6c6728f1cbbbe6"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qemu-*
install_license COPYING

# check if we need to use a more recent glibc
if [[ -f "$prefix/usr/include/sched.h" ]]; then
    GLIBC_ARTIFACT_DIR=$(dirname $(dirname $(dirname $(realpath $prefix/usr/include/sched.h))))
    rsync --archive ${GLIBC_ARTIFACT_DIR}/ /opt/${target}/${target}/sys-root/
fi

# include `falloc` header in `strace.c` (requires glibc 2.25)
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_falloc.patch"

if [[ "${target}" == *-*-musl ]]; then
    # fix messy header situation on musl
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_syscall.patch"

    # include kernel headers for a definition of speculation control prctls (musl 1.1.20)
    sed -i 's/#include <sys\/prctl.h>/#include <linux\/prctl.h>/g' linux-user/syscall.c
fi

# disable tests
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_disable_tests.patch"

# properly link to rt
#atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_link_rt.patch"

# recurse on execve
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_execve.patch"

./configure --prefix=$prefix --host-cc="${HOSTCC}" \
    --extra-cflags="-I${prefix}/include -Wno-unused-result" \
    --target-list="aarch64-linux-user ppc64le-linux-user i386-linux-user x86_64-linux-user arm-linux-user" \
    --static

make -j${nproc}

make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]
platforms = expand_cxxstring_abis(platforms)

# some platforms need a newer glibc, because the default one is too old
glibc_platforms = filter(platforms) do p
    libc(p) == "glibc" && proc_family(p) in ["intel", "power"]
end

# The products that we will ensure are always built
products = [
    ExecutableProduct("qemu-aarch64"            , :qemu_aarch64            ),
    ExecutableProduct("qemu-arm"                , :qemu_arm                ),
    ExecutableProduct("qemu-i386"               , :qemu_i386               ),
    ExecutableProduct("qemu-ppc64le"            , :qemu_ppc64le            ),
    ExecutableProduct("qemu-x86_64"             , :qemu_x86_64             ),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Glib_jll"),
    BuildDependency("PCRE2_jll"),
    BuildDependency("Libiconv_jll"),

    # qemu needs glibc >=2.14 for CLOCK_BOOTTIME
    BuildDependency(PackageSpec(name = "Glibc_jll", version = v"2.17");
                    platforms=glibc_platforms),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8", julia_compat="1.6",
               lock_microarchitecture=false)
