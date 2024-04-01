# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Openresty"
version = v"1.21.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://openresty.org/download/openresty-$(version).1.tar.gz", "0c5093b64f7821e85065c99e5d4e6cc31820cfd7f37b9a0dec84209d87a2af99"),
    ArchiveSource("https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.bz2", "4dae6fdcd2bb0bb6c37b5f97c33c2be954da743985369cddac3546e3218bffb8"),
    ArchiveSource("https://www.openssl.org/source/openssl-1.1.1p.tar.gz", "bf61b62aaa66c7c7639942a94de4c9ae8280c08f17d4eac2e44644d9fc8ace6f"),
    ArchiveSource("https://www.zlib.net/zlib-1.2.12.tar.gz", "91844808532e5ce316b3c010929493c0244f3d37593afd6de04f71821d5136d9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openresty-*/
export SUPER_VERBOSE=1
./configure --prefix=${prefix} \
    --with-cc=$CC \
    --with-zlib=$WORKSPACE/srcdir/zlib-1.2.12 \
    --with-openssl=$WORKSPACE/srcdir/openssl-1.1.1p \
    --with-pcre=$WORKSPACE/srcdir/pcre-8.45 \
    --with-pcre-jit
make
make install
rm ${bindir}/openresty
ln -s ../nginx/sbin/nginx ${bindir}/openresty
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
