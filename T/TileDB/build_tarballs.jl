using BinaryBuilder

name = "TileDB"
version = v"2.24.2"

sources = [
    GitSource("https://github.com/TileDB-Inc/TileDB.git",
              "76cd03c39d459b7659ccccb692864d81dd87d36c"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/TileDB*

for patch in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${patch}
done

mkdir build

export TILEDB_DISABLE_AUTO_VCPKG=1

cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DTILEDB_INSTALL_LIBDIR=${libdir} \
    -DTILEDB_WERROR=OFF \
    -DTILEDB_STATS=OFF \
    -DTILEDB_TESTS=OFF \
    -DTILEDB_S3=OFF \
    -DTILEDB_AZURE=OFF \
    -DTILEDB_GCS=OFF \
    -DTILEDB_HDFS=OFF \
    -DTILEDB_SERIALIZATION=OFF \
    -DTILEDB_WEBP=OFF

make -j${nproc}
make install-tiledb
"""

platforms = supported_platforms()

products = [LibraryProduct("libtiledb", :libtiledb)]

dependencies = Dependency.(["Zlib", "Lz4", "Bzip2", "Zstd"] .* "_jll")

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
