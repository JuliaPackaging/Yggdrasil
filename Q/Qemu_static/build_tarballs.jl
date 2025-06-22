# statically-compiled QEMU binaries, suitable for e.g. use within a container.

using BinaryBuilder, BinaryBuilderBase, Pkg

name = "Qemu_static"
version = v"7.2.9"

# Collection of sources required to build libffi
sources = [
    ArchiveSource("https://download.qemu.org/qemu-$(version).tar.xz",
                  "73f6583d68cc5af36ebc95feabc9df53098ccdce4278084cce2938babf28ab4a"),
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

# disable tests
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_disable_tests.patch"

# properly link to rt
#atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_link_rt.patch"

# recurse on execve
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_execve.patch"

# XXX: qemu uses meson, but uses a complex configure script to invoke it,
#      so we can't just set --cross-file directly. instead, we need to set
#      --cross-prefix to convince it's cross compiling, but that then requires
#      specific binaries to be present there
cross_prefix=$(dirname $(which gcc))
ln -s $(which pkg-config) $cross_prefix
./configure --prefix=$prefix --cross-prefix="$cross_prefix/" \
    --extra-cflags="-I${prefix}/include -Wno-unused-result" \
    --target-list="aarch64-linux-user ppc64le-linux-user i386-linux-user x86_64-linux-user arm-linux-user" \
    --static

make -j${nproc}

make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(Sys.islinux, platforms)              # we're using linux user-mode emulation
filter!(p -> libc(p) == "glibc", platforms)  # binaries are statically linked,
                                             # so why bother with musl
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
