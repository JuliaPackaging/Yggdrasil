using BinaryBuilder

name = "LibSSH2"
version = v"1.10.0"

# Collection of sources required to build LibSSH2
sources = [
    ArchiveSource("https://github.com/libssh2/libssh2/releases/download/libssh2-$(version)/libssh2-$(version).tar.gz",
                  "2d64e90f3ded394b91d3a2e774ca203a4179f69aebee03003e5a6fa621e41d51"),
    DirectorySource("./bundled"),
]

version = v"1.10.2" # <-- This version number is a lie to update compat bounds

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libssh2*/

# Apply patch to fix v1.10.0 CVE (https://github.com/libssh2/libssh2/issues/649), drop with v1.11
atomic_patch -p1 ../patches/0001-userauth-check-for-too-large-userauth_kybd_auth_name.patch
# Fix import lib name on windows: `liblibssh2.dll.a` ==> `libssh2.dll.a`
# Drop this when a new release contains: https://github.com/libssh2/libssh2/pull/711
atomic_patch -p1 ../patches/0002-libssh2-fix-import-lib-name.patch

BUILD_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DCRYPTO_BACKEND=mbedTLS
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTING=OFF
    -DENABLE_ZLIB_COMPRESSION=OFF
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
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

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.8")
