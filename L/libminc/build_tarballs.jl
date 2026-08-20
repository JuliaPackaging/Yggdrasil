using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "libminc"
version = v"2.5.0"

sources = [
    GitSource("https://github.com/BIC-MNI/libminc.git", "64e883811e12f860e9380a694e3df200e64d44ed") # release-2.5.0
    GitSource("https://github.com/NIST-MNI/minc2-simple.git", "8f161e041ad968fc7bd71c0fba3fdba7f067b9e7") # v2.21.0
]

script = raw"""
cd ${WORKSPACE}/srcdir/libminc
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DLIBMINC_BUILD_SHARED_LIBS:BOOL=ON \
    -DLIBMINC_MINC1_SUPPORT:BOOL=ON \
    -DBUILD_TESTING:BOOL=OFF \
    -DLIBMINC_USE_NIFTI:BOOL=OFF \
    -DLIBMINC_BUILD_EZMINC=OFF
make -j${nproc}
make install

cd ../../minc2-simple
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_TESTING:BOOL=OFF \
    -DLIBMINC_DIR:PATH=$prefix/lib/cmake
make -j${nproc}
make install
    
install_license ${WORKSPACE}/srcdir/libminc/COPYING
"""

platforms = supported_platforms()

# Disable Darwin, FreeBSD, and Windows.
# Some of these systems could likely be supported with fairly small patches.
filter!(p -> !((Sys.isapple(p) && arch(p) == "aarch64") || Sys.isfreebsd(p)  || Sys.iswindows(p)), platforms)

products = [
    LibraryProduct("libminc2", :libminc2),
    LibraryProduct("libminc2-simple", :libminc2_simple)
]

dependencies = [
   Dependency("HDF5_jll"; compat="2.1.2"),
   Dependency("NetCDF_jll"; compat="401.1000.0"), 
   Dependency("Zlib_jll"; compat="1.2.12"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               julia_compat="1.6", preferred_gcc_version=v"8")
