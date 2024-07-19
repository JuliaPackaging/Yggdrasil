using BinaryBuilder

name = "TileDB"
version = v"2.24.2"

sources = [GitSource("https://github.com/TileDB-Inc/TileDB.git",
                     "76cd03c39d459b7659ccccb692864d81dd87d36c")]

script = raw"""
cd ${WORKSPACE}/srcdir/TileDB*

mkdir build
cd build

cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DTILEDB_WERROR=OFF \
    -DTILEDB_STATS=OFF \
    -DTILEDB_TESTS=OFF \
    ..

make -j${nproc}
make install-tiledb
"""

platforms = supported_platforms()

products = [LibraryProduct("libtiledb", :libtiledb)]

dependencies = Dependency.(["Zlib", "Lz4", "Bzip2", "Zstd"] .* "_jll")

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
