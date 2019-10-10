using BinaryBuilder

name = "Glibc"
version = v"2.25"

# sources to build, such as glibc, linux kernel headers, our patches, etc....
sources = [
    "https://mirrors.kernel.org/gnu/glibc/glibc-$(version.major).$(version.minor).tar.xz" =>
    "067bd9bb3390e79aa45911537d13c3721f1d9d3769931a30c2681bfee66f23a0",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glibc-*/

# patch for avoiding linking in musl libs for a glibc-linked binary
atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_musl_rejection.patch

# Patch to fix u_char_t definition problems
atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_sunrpc_uchar.patch

mkdir -p $WORKSPACE/srcdir/glibc_build
cd $WORKSPACE/srcdir/glibc_build
$WORKSPACE/srcdir/glibc-*/configure --prefix=/usr \
	--host=${target} \
	--disable-multilib \
	--disable-werror

make -j${nproc}

# Install to the main prefix and also to the sysroot.
make install install_root=${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64; libc=:glibc),
    Linux(:i686; libc=:glibc),
    Linux(:aarch64; libc=:glibc),
    Linux(:armv7l; libc=:glibc),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libc", :libc; dont_dlopen=true),
    LibraryProduct("libdl", :libld; dont_dlopen=true),
    LibraryProduct("libm", :libm; dont_dlopen=true),
    LibraryProduct("libpthread", :libpthread; dont_dlopen=true),
    LibraryProduct("librt", :librt; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)
