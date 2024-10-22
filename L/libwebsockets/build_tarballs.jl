# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "libwebsockets"
version = v"4.3.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/warmcat/libwebsockets.git", "5102a5c8d6110b25a01492fcf96fb668b13dd6e7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libwebsockets

mkdir build && cd build

cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DZLIB_LIBRARY=${libdir}/libz.${dlext} \
    -DZLIB_INCLUDE_DIR=${includedir} \
    -DLWS_WITH_HTTP2=1 \
    -DLWS_WITHOUT_TESTAPPS=1

make -j${nproc}
make install
""" 

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude= x -> (Sys.iswindows(x)))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libwebsockets"], :libwebsockets)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="1.1.23"), # OpenSSL_jll 1.1.23 = OpenSSL 1.1.1w
    Dependency("Zlib_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")