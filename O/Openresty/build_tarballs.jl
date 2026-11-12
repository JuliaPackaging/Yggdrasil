# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Openresty"
version = v"1.29.203"
upstream_version = "1.29.2.3"

# Collection of sources required to complete build.
# Openresty requires static linking of these libraries, hence sources are provided so that they are compiled in.
sources = [
    ArchiveSource("https://openresty.org/download/openresty-$(upstream_version).tar.gz", "315e49fa4568747fec4bdada9614d2ba287e7aed4b3430d7ea25685e24cc43ff"),
    ArchiveSource("https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.47/pcre2-10.47.tar.bz2", "47fe8c99461250d42f89e6e8fdaeba9da057855d06eb7fc08d9ca03fd08d7bc7"),
    ArchiveSource("https://github.com/openssl/openssl/releases/download/openssl-3.5.5/openssl-3.5.5.tar.gz", "b28c91532a8b65a1f983b4c28b7488174e4a01008e29ce8e69bd789f28bc2a89"),
    ArchiveSource("https://www.zlib.net/zlib-1.3.2.tar.gz", "bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openresty-*/
export SUPER_VERBOSE=1
./configure --prefix=${prefix} \
    --with-cc=$CC \
    --with-zlib=$WORKSPACE/srcdir/zlib-1.3.2 \
    --with-openssl=$WORKSPACE/srcdir/openssl-3.5.5 \
    --with-pcre=$WORKSPACE/srcdir/pcre2-10.47 \
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
