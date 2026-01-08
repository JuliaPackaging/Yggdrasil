using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "RDKit"
version = v"2025.09.3"

sources = [
    GitSource("https://github.com/rdkit/rdkit.git", "fd677c59b21ffbf50157752102216660324ac1f1"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/rdkit

# Apply patches
atomic_patch -p1 ../patches/do-not-build-cffi-test.patch
atomic_patch -p1 ../patches/disable-catch2.patch
atomic_patch -p1 ../patches/fix-windows-zlib.patch

FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    FLAGS+=(-DRDK_BUILD_THREADSAFE_SSS=OFF)
    FLAGS+=(-DBoost_USE_STATIC_LIBS=OFF)
    FLAGS+=(-DBoost_INCLUDE_DIR=${prefix}/include)
    FLAGS+=(-DBoost_LIBRARY_DIR=${prefix}/lib)
fi

mkdir build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_CXX_STANDARD=17 \
    -DRDK_INSTALL_INTREE=OFF \
    -DRDK_BUILD_INCHI_SUPPORT=ON \
    -DRDK_BUILD_PYTHON_WRAPPERS=OFF \
    -DRDK_BUILD_CFFI_LIB=ON \
    -DRDK_BUILD_FREETYPE_SUPPORT=ON \
    -DRDK_BUILD_CPP_TESTS=OFF \
    -DRDK_BUILD_SLN_SUPPORT=OFF \
    -DRDK_TEST_MULTITHREADED=OFF \
    -DRDK_BUILD_COORDGEN_SUPPORT=OFF \
    -DRDK_BUILD_MAEPARSER_SUPPORT=OFF \
    -DRDK_BUILD_CHEMDRAW_SUPPORT=OFF \
    -DRDK_USE_URF=OFF \
    -DBoost_ROOT=${prefix} \
    "${FLAGS[@]}" \
    ..

make -j${nproc}
make install
"""

# Adapted from https://github.com/JuliaPackaging/Yggdrasil/blob/60500f4eaba2534332f963eec85e8916ce9a2fcd/D/Doxygen/build_tarballs.jl#L46C1-L46C62
sources, script = require_macos_sdk("10.14", sources, script)

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
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("boost_jll"; compat="=1.87.0"),
    BuildDependency("Eigen_jll"),
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"11", julia_compat="1.6")
