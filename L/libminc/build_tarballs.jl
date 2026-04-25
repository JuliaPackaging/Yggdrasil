using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "libminc"
version = v"2.5.0"

sources = [
    #ArchiveSource("https://github.com/BIC-MNI/libminc/archive/refs/tags/release-2.4.06.tar.gz", "cd5c6da9cd98be225a4bd3b8d712bd5292fc24f434cae732fa37af866c2db5b3"),
    GitSource("git@github.com:BIC-MNI/libminc.git","64e883811e12f860e9380a694e3df200e64d44ed") # release-2.5.0
    GitSource("git@github.com:NIST-MNI/minc2-simple.git","8f161e041ad968fc7bd71c0fba3fdba7f067b9e7") # v2.21.0
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
    -DBUILD_TESTING:BOOL=ON \
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

#platforms = supported_platforms()
# right now only linux on x86_64 is tested
platforms = [
    Platform("x86_64", "Linux"; libc="glibc", libgfortran_version="5.0.0", mpi="mpitrampoline"),
]

# should i do this?
#platforms = expand_cxxstring_abis(platforms)
#platforms = expand_gfortran_versions(platforms)
#platforms, platform_dependencies = MPI.augment_platforms(platforms)


products = [
    LibraryProduct("libminc2", :libminc2),
    LibraryProduct("libminc2-simple", :libminc2_simple)
]

dependencies = [
   Dependency("HDF5_jll";  compat="~1.14.6"), # should be compatible with NetCDF
   Dependency("NetCDF_jll";compat="~401.900.300"), 
]

#append!(dependencies, platform_dependencies)


build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    julia_compat="1.7" #, preferred_gcc_version=v"5"
  )
