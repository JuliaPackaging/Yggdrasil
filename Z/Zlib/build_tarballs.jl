using BinaryBuilder

# zlib version
name = "Zlib"
version = v"1.2.12"


# Collection of sources required to build zlib
sources = [
    ArchiveSource("https://zlib.net/zlib-$(version).tar.gz",
                  "91844808532e5ce316b3c010929493c0244f3d37593afd6de04f71821d5136d9"),
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

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libz", :libz),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
