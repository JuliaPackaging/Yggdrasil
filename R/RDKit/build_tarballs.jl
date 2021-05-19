using BinaryBuilder, Pkg

julia_version = v"1.6.0"

name = "RDKit"
version = v"2021.09.1pre"

sources = [
    GitSource("https://github.com/rdkit/rdkit.git", "f5a54af475cc38a82b2c69a8a44193a222fe92fc"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/rdkit
mkdir build
cd build
cmake \
-DCMAKE_BUILD_TYPE=Release \
-DRDK_INSTALL_INTREE=OFF \
-DRDK_BUILD_INCHI_SUPPORT=ON \
-DRDK_BUILD_PYTHON_WRAPPERS=OFF \
-DRDK_BUILD_CFFI_LIB=ON \
-DRDK_BUILD_FREETYPE_SUPPORT=ON \
-DRDK_BUILD_CPP_TESTS=OFF \
-RDK_BUILD_SLN_SUPPORT=OFF \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_PREFIX_PATH=${prefix} \
..
make -j${nproc}
make install
"""

platforms = [
    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
    Platform("aarch64", "linux"),
    Platform("x86_64", "macos"),
    # Platform("aarch64", "macos"),
]

platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("librdkitcffi", :librdkitcffi),
]

dependencies = [
    Dependency("FreeType2_jll"),
    Dependency("boost_jll"),
    BuildDependency("Eigen_jll"),
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    preferred_gcc_version=v"5", julia_compat="^$(julia_version.major).$(julia_version.minor)")
