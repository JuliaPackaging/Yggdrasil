using BinaryBuilder

name = "CechCore"
version = v"1.0.0"

sources = [
    GitSource(
        "https://github.com/profsms/CechCore.git",
        "3681b0d9d42040dc6e2caa04c5b957d0983aaabe";
        unpack_target = "src",
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/src

test -f CMakeLists.txt || (echo "ERROR: CMakeLists.txt not found"; exit 1)
test -f src/cech_core.cpp || (echo "ERROR: src/cech_core.cpp not found"; exit 1)
test -f src/cech_core.hpp || (echo "ERROR: src/cech_core.hpp not found"; exit 1)

mkdir build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install
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