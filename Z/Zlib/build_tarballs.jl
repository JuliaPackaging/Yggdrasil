using BinaryBuilder

# zlib version
name = "Zlib"
version = v"1.2.11"


# Collection of sources required to build zlib
sources = [
    ArchiveSource("https://zlib.net/zlib-$(version).tar.gz",
                  "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zlib-*
mkdir build && cd build

# We use `-DUNIX=true` to ensure that it is always named `libz` instead of `libzlib` or something ridiculous like that.
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DUNIX=true \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    ..
make install -j${nproc}
install_license ../README
"""

# Build for all platforms
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libz", :libz),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
