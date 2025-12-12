# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "wolfSSL"
version = v"5.7.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wolfSSL/wolfssl.git", "00e42151ca061463ba6a95adb2290f678cbca472"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wolfssl*

./autogen.sh
CFLAGS="-msse4.2" ./configure \
    --disable-crypttests \
    --disable-examples \
    --enable-maxfragment \
    --enable-aesni \
    --enable-intelasm \
    --prefix=${prefix}

make -j${nproc}
make install
"""

sources, script = require_macos_sdk("10.14", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libwolfssl", :libwolfssl)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
