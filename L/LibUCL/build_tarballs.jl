using BinaryBuilder

name = "LibUCL"
version = v"0.8.2"

sources = [GitSource("https://github.com/vstakhov/libucl.git",
                     "a615938cec3ae35c70aa2fb9845c9c12e5c7326f")]

script = raw"""
cd ${WORKSPACE}/srcdir/libucl*
mkdir build
cd build
cmake .. \
    -DENABLE_URL_INCLUDE=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

platforms = supported_platforms()

products = [LibraryProduct("libucl", :libucl)]

dependencies = [Dependency("LibCURL_jll")]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
