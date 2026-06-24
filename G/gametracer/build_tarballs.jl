using BinaryBuilder

name = "gametracer"
version = v"0.2.1"

const GIT_SHA = "49ba14e396ddc21fbcd54621e610d355b7106c5e"

sources = [
    GitSource("https://github.com/QuantEcon/gametracer.git", GIT_SHA),
]

script = raw"""
cd "${WORKSPACE}/srcdir/gametracer"

extra_cmake_flags=()
if [[ "${target}" == *-mingw* ]]; then
    extra_cmake_flags+=(-DCMAKE_SHARED_LINKER_FLAGS=-static-libstdc++)
fi

cmake -S c_api -B build \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${prefix}" \
    "${extra_cmake_flags[@]}"

cmake --build build --parallel "${nproc}"
cmake --install build
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libgametracer", :libgametracer),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6")
