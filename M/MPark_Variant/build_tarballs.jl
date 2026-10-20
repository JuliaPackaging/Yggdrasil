using BinaryBuilder

name = "MPark_Variant"
version = v"1.4.0"

sources = [
    GitSource("https://github.com/mpark/variant", "4988879a9f5a95d72308eca2b1779db6ed9b135d"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/variant
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
