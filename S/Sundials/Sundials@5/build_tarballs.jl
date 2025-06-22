using BinaryBuilder

name = "Sundials"
version = v"5.2.3" # <-- There is no version 5.2.x, but we need to change versions for new Julia releases

# Collection of sources required to build Sundials
sources = [
    GitSource("https://github.com/LLNL/sundials.git",
              "8264ba5614fd9578786e5e8a3ba9f703ff795361"),
    DirectorySource("../bundled@5"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sundials*

# Don't run the KLU and LAPACK tests during build since we are in a cross compile environment
atomic_patch -p1 ../patches/Sundials_NoKLUTest.patch
atomic_patch -p1 ../patches/Sundials_NoLAPACKTest.patch

if [[ ${nbits} == 64 ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/Sundials_Fortran.patch
fi

# Set up CFLAGS
if [[ "${target}" == *-mingw* ]]; then
    LAPACK_NAME=-lblastrampoline-5
    atomic_patch -p1 ../patches/Sundials_windows.patch
    # Work around https://github.com/LLNL/sundials/issues/29
    export CFLAGS="-DBUILD_SUNDIALS_LIBRARY"
    # See https://github.com/LLNL/sundials/issues/35
    atomic_patch -p1 ../patches/Sundials_lapackband.patch
    # When looking for KLU libraries, CMake searches only for import libraries,
    # this patch ensures we look also for shared libraries.
    atomic_patch -p1 ../patches/Sundials_findklu_suffixes.patch
else
    LAPACK_NAME=-lblastrampoline
fi

# Build
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DEXAMPLES_ENABLE_C=OFF \
    -DKLU_ENABLE=ON \
    -DKLU_INCLUDE_DIR="${includedir}/suitesparse" \
    -DKLU_LIBRARY_DIR="${libdir}" \
    -DLAPACK_ENABLE=ON \
    -DLAPACK_LIBRARIES:STRING="${LAPACK_NAME}" \
    ..
make -j${nproc}
make install

# Move libraries to ${libdir} on Windows
if [[ "${target}" == *-mingw* ]]; then
    mv ${prefix}/lib/libsundials_*.${dlext} "${libdir}"
fi
"""

# We attempt to build for all defined platforms
platforms = filter!(p -> arch(p) != "powerpc64le", supported_platforms())
platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct("libsundials_arkode", :libsundials_arkode),
    LibraryProduct("libsundials_cvode", :libsundials_cvode),
    LibraryProduct("libsundials_cvodes", :libsundials_cvodes),
    LibraryProduct("libsundials_ida", :libsundials_ida),
    LibraryProduct("libsundials_idas", :libsundials_idas),
    LibraryProduct("libsundials_kinsol", :libsundials_kinsol),
    LibraryProduct("libsundials_nvecmanyvector", :libsundials_nvecmanyvector),
    LibraryProduct("libsundials_nvecserial", :libsundials_nvecserial),
    LibraryProduct("libsundials_sunlinsolband", :libsundials_sunlinsolband),
    LibraryProduct("libsundials_sunlinsoldense", :libsundials_sunlinsoldense),
    LibraryProduct("libsundials_sunlinsolklu", :libsundials_sunlinsolklu),
    LibraryProduct("libsundials_sunlinsollapackband", :libsundials_sunlinsollapackband),
    LibraryProduct("libsundials_sunlinsollapackdense", :libsundials_sunlinsollapackdense),
    LibraryProduct("libsundials_sunlinsolpcg", :libsundials_sunlinsolpcg),
    LibraryProduct("libsundials_sunlinsolspbcgs", :libsundials_sunlinsolspbcgs),
    LibraryProduct("libsundials_sunlinsolspfgmr", :libsundials_sunlinsolspfgmr),
    LibraryProduct("libsundials_sunlinsolspgmr", :libsundials_sunlinsolspgmr),
    LibraryProduct("libsundials_sunlinsolsptfqmr", :libsundials_sunlinsolsptfqmr),
    LibraryProduct("libsundials_sunmatrixband", :libsundials_sunmatrixband),
    LibraryProduct("libsundials_sunmatrixdense", :libsundials_sunmatrixdense),
    LibraryProduct("libsundials_sunmatrixsparse", :libsundials_sunmatrixsparse),
    LibraryProduct("libsundials_sunnonlinsolfixedpoint", :libsundials_sunnonlinsolfixedpoint),
    LibraryProduct("libsundials_sunnonlinsolnewton", :libsundials_sunnonlinsolnewton),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("libblastrampoline_jll"; compat="5.8.0"),
    Dependency("SuiteSparse_jll"; compat="7.5"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6", julia_compat="1.11")
