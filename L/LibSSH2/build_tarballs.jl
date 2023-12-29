using BinaryBuilder

name = "LibSSH2"
version = v"1.11.0"

# Collection of sources required to build LibSSH2
sources = [
    ArchiveSource("https://github.com/libssh2/libssh2/releases/download/libssh2-$(version)/libssh2-$(version).tar.gz",
                  "3736161e41e2693324deb38c26cfdc3efe6209d634ba4258db1cecff6a5ad461"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libssh2*/

# Apply patch from https://github.com/libssh2/libssh2/pull/1054
atomic_patch -p1 ../patches/0001-mbedtls-use-more-size_t-to-sync-up-with-crypto.h.patch

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

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
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libssh2", :libssh2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("MbedTLS_jll"; compat="~2.28.0"),
    BuildDependency("LLVMCompilerRT_jll"; platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10")
