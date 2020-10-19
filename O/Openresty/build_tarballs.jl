# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Openresty"
version = v"1.15.8"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://openresty.org/download/openresty-1.15.8.3.tar.gz", "b68cf3aa7878db16771c96d9af9887ce11f3e96a1e5e68755637ecaff75134a8"),
    ArchiveSource("https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz", "0b8e7465dc5e98c757cc3650a20a7843ee4c3edf50aaf60bb33fd879690d2c73"),
    ArchiveSource("https://www.openssl.org/source/openssl-1.0.2t.tar.gz", "14cb464efe7ac6b54799b34456bd69558a749a4931ecfd9cf9f71d7881cac7bc"),
    ArchiveSource("https://www.zlib.net/zlib-1.2.11.tar.gz", "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd openresty-1.15.8.3/
./configure --prefix=$prefix --with-cc=$CC --with-zlib=$WORKSPACE/srcdir/zlib-1.2.11 --with-openssl=$WORKSPACE/srcdir/openssl-1.0.2t --with-pcre=$WORKSPACE/srcdir/pcre-8.43 --with-pcre-jit
make -j${nproc}
make install
rm $prefix/bin/openresty 
cd $prefix/bin/
ln -fs ../nginx/sbin/nginx ./openresty
install_license $prefix/COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("openresty", :openresty),
    ExecutableProduct("opm", :opm),
    ExecutableProduct("resty", :resty),
    FileProduct("luajit", :luajit_dir),
    FileProduct("lualib", :lualib_dir),
    FileProduct("nginx", :nginx_dir),
    FileProduct("site", :site_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
