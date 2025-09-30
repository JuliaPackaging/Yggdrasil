# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "libwebsockets"
version = v"4.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/warmcat/libwebsockets.git", "e636b7bd133c4c0bfbdbf0d77afebdb20e09a5a2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libwebsockets
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DGENCERTS=OFF \
    -DCMAKE_C_FLAGS="${CFLAGS} -Duv_poll_init_socket=uv_poll_init" \
    -DZLIB_LIBRARY=${libdir}/libz.${dlext} \
    -DZLIB_INCLUDE_DIR=${includedir} \
    -DLWS_WITH_ACCESS_LOG=ON \
    -DLWS_WITHOUT_EXTENSIONS=OFF \
    -DLWS_WITHOUT_TESTAPPS=ON \
    -DLWS_WITH_LIBUV=ON \
    -DLWS_WITH_SHARED=ON \
    -DLWS_WITH_STATIC=OFF \
    -DLWS_WITH_SSL=ON \
    -DLWS_WITH_ZLIB=ON \
    -DLWS_WITH_MINIMAL_EXAMPLES=OFF \
    -DLWS_IPV6=ON \
    -DLWS_WITH_HTTP2=ON \
    -DLWS_WITH_SOCKS5=ON
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
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("Zlib_jll"),
    Dependency("LibUV_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
