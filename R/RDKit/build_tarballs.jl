using BinaryBuilder, Pkg

name = "RDKit"
version = v"2022.03.1"

sources = [
    GitSource("https://github.com/rdkit/rdkit.git", "7e205e0d93a3046c1eaab37120c9f6971194ddf2"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/rdkit
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    FLAGS+=(-DRDK_BUILD_THREADSAFE_SSS=OFF -DRDK_USE_URF=OFF)
fi
if [[ "${proc_family}" == intel ]]; then
    FLAGS+=(-DRDK_OPTIMIZE_POPCNT=ON)
else
    # For some reasons they think unconditionally enabling this option by
    # default on all platforms is a good idea, so we have to manually disable it
    # on non-Intel platforms
    FLAGS+=(-DRDK_OPTIMIZE_POPCNT=OFF)
fi
mkdir build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DRDK_INSTALL_INTREE=OFF \
    -DRDK_BUILD_INCHI_SUPPORT=ON \
    -DRDK_BUILD_PYTHON_WRAPPERS=OFF \
    -DRDK_BUILD_CFFI_LIB=ON \
    -DRDK_BUILD_FREETYPE_SUPPORT=ON \
    -DRDK_BUILD_CPP_TESTS=OFF \
    -DRDK_BUILD_SLN_SUPPORT=OFF \
    -DRDK_TEST_MULTITHREADED=OFF \
    "${FLAGS[@]}" \
    ..
make -j${nproc}
make install
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("librdkitcffi", :librdkitcffi),
]

dependencies = [
    Dependency("FreeType2_jll"),
    Dependency("boost_jll"; compat="=1.76.0"),
    BuildDependency("Eigen_jll"),
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               preferred_gcc_version=v"7", julia_compat="1.6")
