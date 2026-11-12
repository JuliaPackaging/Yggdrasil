using BinaryBuilder, Pkg

name = "lwbgt"
version = v"1.1.0"

sources = [
    GitSource(
        "https://github.com/zyf0717/lwbgt.git",
        "b6c49eff1d34738ae40f1d6b51a62cc3a5d0e83d",
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
install_license LICENSE NOTICE src/LicenseRef-UChicago-Argonne-WBGT-1.1.txt
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
