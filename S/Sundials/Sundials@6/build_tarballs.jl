using BinaryBuilder

name = "Sundials"
version = v"6.7.0"

# Collection of sources required to build Sundials
sources = [
    ArchiveSource("https://github.com/LLNL/sundials/releases/download/v$(version)/sundials-$(version).tar.gz",
                  "5f113a1564a9d2d98ff95249f4871a4c815a05dbb9b8866a82b13ab158c37adb"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sundials*

if [[ ${nbits} == 64 ]]; then
    cd $WORKSPACE/srcdir/sundials*/cmake
    atomic_patch -p2 $WORKSPACE/srcdir/patches/SundialsSetupCompilers.patch
fi

# Set up CFLAGS
cd $WORKSPACE/srcdir/sundials*/cmake/tpl
if [[ "${target}" == *-mingw* ]]; then
    LAPACK_NAME="-L${libdir} -lblastrampoline-5"
    atomic_patch -p2 $WORKSPACE/srcdir/patches/Sundials_windows.patch
    # Work around https://github.com/LLNL/sundials/issues/29
    # When looking for KLU libraries, CMake searches only for import libraries,
    # this patch ensures we look also for shared libraries.
    atomic_patch -p2 $WORKSPACE/srcdir/patches/Sundials_findklu_suffixes.patch

    #export CFLAGS="-DBUILD_SUNDIALS_LIBRARY"
    # See https://github.com/LLNL/sundials/issues/35
    #atomic_patch -p1 $WORKSPACE/srcdir/patches/Sundials_lapackband.patch
else
    LAPACK_NAME="-L{$libdir} -lblastrampoline"
fi

# Build
cd $WORKSPACE/srcdir/sundials*
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DEXAMPLES_ENABLE_C=OFF \
    -DENABLE_KLU=ON \
    -DKLU_INCLUDE_DIR="${includedir}/suitesparse" \
    -DKLU_LIBRARY_DIR="${libdir}" \
    -DKLU_WORKS=ON \
    -DENABLE_LAPACK=ON \
    -DLAPACK_LIBRARIES:STRING="${LAPACK_NAME}" \
    -DLAPACK_WORKS=ON \
    ..
make -j${nproc}
make install

# Move libraries to ${libdir} on Windows
if [[ "${target}" == *-mingw* ]]; then
    mv ${prefix}/lib/libsundials_*.${dlext} "${libdir}"
fi
"""

# We attempt to build for all defined platforms
platforms = supported_platforms()
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
    Dependency("libblastrampoline_jll"),
    Dependency("SuiteSparse_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6", julia_compat="1.11")
