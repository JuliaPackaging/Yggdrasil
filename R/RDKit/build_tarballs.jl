using BinaryBuilder, Pkg

name = "RDKit"
version = v"2024.09.4"

sources = [
    GitSource("https://github.com/rdkit/rdkit.git", "558465015189358b22b564929cdf1087e3baddc2"),
    #DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/rdkit

# Windows build fails to link a test, despite the fact we don't want tests.
# atomic_patch -p1 ../patches/do-not-build-cffi-test.patch

FLAGS=()
# if [[ "${target}" == *-mingw* ]]; then
#     FLAGS+=(-DRDK_BUILD_THREADSAFE_SSS=OFF)
# fi

mkdir build
cd build
# cmake \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
#     -DCMAKE_INSTALL_PREFIX=${prefix} \
#     -DRDK_INSTALL_INTREE=OFF \
#     -DRDK_BUILD_INCHI_SUPPORT=ON \
#     -DRDK_BUILD_PYTHON_WRAPPERS=OFF \
#     -DRDK_BUILD_CFFI_LIB=ON \
#     -DRDK_BUILD_FREETYPE_SUPPORT=ON \
#     -DRDK_BUILD_CPP_TESTS=OFF \
#     -DRDK_BUILD_SLN_SUPPORT=OFF \
#     -DRDK_TEST_MULTITHREADED=OFF \
#     "${FLAGS[@]}" \

cmake \
    -G "MSYS Makefiles" \
    -DRDK_INSTALL_INTREE=OFF \
    -DRDK_INSTALL_STATIC_LIBS=OFF \
    -DRDK_BUILD_CPP_TESTS=ON \
    -DRDK_BUILD_COORDGEN_SUPPORT=ON \
    -DRDK_BUILD_MAEPARSER_SUPPORT=ON \
    -DRDK_OPTIMIZE_POPCNT=ON \
    -DRDK_BUILD_TEST_GZIP=ON \
    -DRDK_BUILD_FREESASA_SUPPORT=ON \
    -DRDK_BUILD_AVALON_SUPPORT=ON \
    -DRDK_BUILD_INCHI_SUPPORT=ON \
    -DRDK_BUILD_CFFI_LIB=ON \
    -DRDK_CFFI_STATIC=OFF \
    -DRDK_BUILD_THREADSAFE_SSS=ON \
    -DRDK_BUILD_SWIG_WRAPPERS=OFF \
    -DRDK_SWIG_STATIC=OFF \
    -DRDK_BUILD_FREETYPE_SUPPORT=ON \
    -DRDK_TEST_MULTITHREADED=ON \
    -DRDK_INSTALL_DLLS_MSVC=ON \
    -DRDK_BUILD_PYTHON_WRAPPERS=OFF \
    -DRDK_BUILD_PGSQL=OFF \
    -DRDK_PGSQL_STATIC=OFF \
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
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("boost_jll"; compat="=1.76.0"),
    BuildDependency("Eigen_jll"),
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # GCC 8 is needed for `std::from_chars`
               preferred_gcc_version=v"8", julia_compat="1.6")
