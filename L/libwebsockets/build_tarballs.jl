# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "libwebsockets"
version = v"4.3.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/warmcat/libwebsockets.git", "4415e84c095857629863804e941b9e1c2e9347ef"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libwebsockets
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DZLIB_LIBRARY=${libdir}/libz.${dlext} \
    -DZLIB_INCLUDE_DIR=${includedir} \
    -DLWS_WITH_ACCESS_LOG=1 \
    -DLWS_WITHOUT_EXTENSIONS=0 \
    -DLWS_WITHOUT_TESTAPPS=1
cmake --build build --parallel ${nproc}
cmake --install build
""" 

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude = Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libwebsockets"], :libwebsockets)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.8"),
    Dependency("Zlib_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
