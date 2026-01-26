# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "wolfSSL"
version = v"5.8.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wolfSSL/wolfssl.git", "59f4fa568615396fbf381b073b220d1e8d61e4c2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wolfssl*

./autogen.sh

# NOTE: some non-x86_64 CPUs support AES-NI as well, but provided assembly seems x86_64-specific
# NOTE: assembly code has some ELF-specific instructions and doesn't compile for Windows
if [[ ${target} == x86_64-* ]] && [[ ${target} != *-w64-* ]]; then
    ARCHFLAGS="--enable-aesni --enable-intelasm"
else
    ARCHFLAGS=""
fi
CFLAGS=-DLARGE_STATIC_BUFFERS ./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-crypttests \
    --disable-examples \
    --enable-maxfragment \
    $ARCHFLAGS

make -j${nproc}
make install

install_license LICENSING
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
# NOTE: gcc 11+ produces faster code than older ones
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version = v"11")
