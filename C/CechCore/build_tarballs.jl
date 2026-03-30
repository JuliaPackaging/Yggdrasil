using BinaryBuilder

name = "CechCore"
version = v"1.0.0"

sources = [
    GitSource(
        "https://github.com/profsms/CechCore.git",
        "b9797e58fbbf923c6c0c2c42f662795ad477ed41";
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/CechCore

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = expand_cxxstring_abis(supported_platforms())
filter!(p -> arch(p) != "riscv64", platforms)

products = [
    LibraryProduct("libcech", :libcech),
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
    preferred_gcc_version = v"9",
)
