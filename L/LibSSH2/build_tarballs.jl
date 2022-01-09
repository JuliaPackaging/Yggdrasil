using BinaryBuilder

name = "LibSSH2"
version = v"1.10.0"

# Collection of sources required to build LibSSH2
sources = [
#     ArchiveSource("https://github.com/libssh2/libssh2/releases/download/libssh2-$(version)/libssh2-$(version).tar.gz",
#                   "2d64e90f3ded394b91d3a2e774ca203a4179f69aebee03003e5a6fa621e41d51"),
      GitSource("https://github.com/libssh2/libssh2.git", "13ad7b2f5cd67e0dc843098ce19ce8b208368c29")
]

version = v"1.10.1" # <-- This version number is a lie to update compat bounds

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libssh2*/

BUILD_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DCRYPTO_BACKEND=mbedTLS
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTING=OFF
    -DENABLE_ZLIB_COMPRESSION=OFF
    "-DCMAKE_INSTALL_PREFIX=${prefix}"
    "-DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}""
)

mkdir build && cd build

cmake .. "${BUILD_FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libssh2", :libssh2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("MbedTLS_jll"; compat="~2.28.0"),
]

# Note: we explicitly lie about this because we don't have the new
# versioning APIs worked out in BB yet.
version = v"1.10.1"
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
