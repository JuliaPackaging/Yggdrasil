using BinaryBuilder

name = "Emoslib"
version = v"4.5.9"
sources = [
    ArchiveSource("https://confluence.ecmwf.int/download/attachments/3473472/libemos-$version-Source.tar.gz", "e57e02c636dc8f5ccb862a103789b1e927bc985b1e0f2b05abf4f64e86d2f67f"),
]

script = raw"""
cd libemos-*-Source

# This is a cross build, we can't do native compilation.
sed -i 's/-mtune=native//' CMakeLists.txt

mkdir build ; cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_ECCODES=ON \
    -DGRIB_API_LIBRARIES=${libdir}/libeccodes.${dlext} \
    -DGRIB_API_INCLUDE_DIRS=${includedir} \
    ..
make -j${nproc}
make install
install_license ../LICENSE
"""

platforms = supported_platforms()

products = [
    # libemos is not designed to be build as a shared library (see libemos-$version-Source/CMakeLists.txt:39)
    FileProduct("lib/libemos.a", :emos),
]

dependencies = [
    Dependency("eccodes_jll"),
    Dependency("FFTW_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
