using BinaryBuilder, Pkg

name = "SuperCollider"
version = v"3.13.0"

sources = [
    GitSource("https://github.com/supercollider/supercollider.git", "31885032db394f4d2b7d39eaf90e17927383e39d")
]

script = raw"""
cd ${WORKSPACE}/srcdir/supercollider
git submodule update --init --recursive

cmake -G Ninja \
    -S . \
    -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TESTING=OFF \
    -DENABLE_TESTSUITE=OFF \
    -DLIBSCSYNTH=ON \
    -DSC_IDE=OFF \
    -DSC_QT=OFF \
    -DSC_USE_QTWEBENGINE=OFF \
    -DSUPERNOVA=OFF \
    -DNO_X11=ON \
    -DSCLANG_SERVER=OFF

cmake --build build --parallel ${nproc} --target all
cmake --build build --target install
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("scsynth", :scsynth),
    LibraryProduct("libscsynth", :libscsynth),
    ExecutableProduct("supernova", :supernova),
]

dependencies = [
    Dependency("libportaudio_jll", v"19.7.0"),
    Dependency("libsndfile_jll", v"1.1.0"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
