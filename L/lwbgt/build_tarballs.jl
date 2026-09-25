using BinaryBuilder, Pkg

name = "lwbgt"
version = v"1.0.0"

sources = [
    GitSource(
        "https://github.com/zyf0717/lwbgt.git",
        "5b16131eff01c67a5bfa2bdd71df8f41a313422d",
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/lwbgt
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = supported_platforms()

products = [
    LibraryProduct(["liblwbgt", "lwbgt"], :liblwbgt),
]

dependencies = Dependency[]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
)
