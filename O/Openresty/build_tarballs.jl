# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Openresty"
version = v"1.27.1"

# Collection of sources required to complete build.
# Openresty requires static linking of these libraries, hence sources are provided so that they are compiled in.
sources = [
    ArchiveSource("https://openresty.org/download/openresty-$(version).1.tar.gz", "79b071e27bdc143d5f401d0dbf504de4420070d867538c5edc2546d0351fd5c0"),
    ArchiveSource("https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.bz2", "4dae6fdcd2bb0bb6c37b5f97c33c2be954da743985369cddac3546e3218bffb8"),
    ArchiveSource("https://github.com/openssl/openssl/releases/download/openssl-3.0.15/openssl-3.0.15.tar.gz", "23c666d0edf20f14249b3d8f0368acaee9ab585b09e1de82107c66e1f3ec9533"),
    ArchiveSource("https://www.zlib.net/zlib-1.3.1.tar.gz", "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23")
]


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openresty-*/
export SUPER_VERBOSE=1
./configure --prefix=${prefix} \
    --with-cc=$CC \
    --with-zlib=$WORKSPACE/srcdir/zlib-1.3.1 \
    --with-openssl=$WORKSPACE/srcdir/openssl-3.0.15 \
    --with-pcre=$WORKSPACE/srcdir/pcre-8.45 \
    --with-pcre-jit
make
make install
install_license $prefix/COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("openresty", :openresty),
    ExecutableProduct("opm", :opm),
    ExecutableProduct("resty", :resty),
    FileProduct("luajit", :luajit_dir),
    FileProduct("lualib", :lualib_dir),
    FileProduct("nginx", :nginx_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; lock_microarchitecture=false)
