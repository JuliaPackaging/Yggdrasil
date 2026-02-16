using BinaryBuilder

name = "gametracer"
version = v"0.2.1"
sources = [
    GitSource("https://github.com/QuantEcon/gametracer.git",
        "12aa4bb906a9d5a6ecd804cd26e7a2757a9cce50"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/gametracer

# Remove any corrupted Mac OS resource fork files that may interfere with CMake
rm -f /usr/share/cmake/Modules/Compiler/._*

cmake -S c_api -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libgametracer", :libgametracer),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"8",
    julia_compat="1.6")
