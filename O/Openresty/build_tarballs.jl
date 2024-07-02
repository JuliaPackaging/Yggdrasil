# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Openresty"
version = v"1.25.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://openresty.org/download/openresty-$(version).1.tar.gz", "32ec1a253a5a13250355a075fe65b7d63ec45c560bbe213350f0992a57cd79df"),
    ArchiveSource("https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.bz2", "4dae6fdcd2bb0bb6c37b5f97c33c2be954da743985369cddac3546e3218bffb8"),
    ArchiveSource("https://www.openssl.org/source/openssl-3.3.0.tar.gz", "53e66b043322a606abf0087e7699a0e033a37fa13feb9742df35c3a33b18fb02"),
    ArchiveSource("https://www.zlib.net/zlib-1.3.1.tar.gz", "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openresty-*/
export SUPER_VERBOSE=1
./configure --prefix=${prefix} \
    --with-cc=$CC \
    --with-zlib=$WORKSPACE/srcdir/zlib-1.3.1 \
    --with-openssl=$WORKSPACE/srcdir/openssl-3.3.0 \
    --with-pcre=$WORKSPACE/srcdir/pcre-8.45 \
    --with-pcre-jit
make -j${nprocs}
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
