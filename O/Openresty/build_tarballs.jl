# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Openresty"
version = v"1.19.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://openresty.org/download/openresty-1.19.9.1.tar.gz", "576ff4e546e3301ce474deef9345522b7ef3a9d172600c62057f182f3a68c1f6"),
    ArchiveSource("https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz", "0b8e7465dc5e98c757cc3650a20a7843ee4c3edf50aaf60bb33fd879690d2c73"),
    ArchiveSource("https://www.openssl.org/source/openssl-1.1.1l.tar.gz", "0b7a3e5e59c34827fe0c3a74b7ec8baef302b98fa80088d7f9153aa16fa76bd1"),
    ArchiveSource("https://www.zlib.net/zlib-1.2.11.tar.gz", "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openresty-*/
export SUPER_VERBOSE=1
./configure --prefix=${prefix} \
    --with-cc=$CC \
    --with-zlib=$WORKSPACE/srcdir/zlib-1.2.11 \
    --with-openssl=$WORKSPACE/srcdir/openssl-1.1.1l \
    --with-pcre=$WORKSPACE/srcdir/pcre-8.43 \
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
