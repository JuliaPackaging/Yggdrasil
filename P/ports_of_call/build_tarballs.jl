using BinaryBuilder

name = "ports_of_call"
version = v"1.7.1"

sources = [
    GitSource("https://github.com/lanl/ports-of-call", "0b1e73b93799cc635ac1c3f8c54f3d9d09f17221"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ports-of-call
cmakeflags=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
)
cmake -Bbuild "${cmakeflags[@]}"
cmake --build build --parallel ${nprocs}
cmake --install build
"""

platforms = supported_platforms()

# This is a header-only library with no build products
products = Product[]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
