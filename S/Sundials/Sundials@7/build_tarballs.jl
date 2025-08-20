using BinaryBuilder

name = "Sundials"
version = v"7.4.0"

# Collection of sources required to build Sundials
sources = [
    GitSource("https://github.com/LLNL/sundials.git",
              "8e17876d3b4d682b4098684b07a85b005a122f81"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sundials*

apk del cmake

# Set up CFLAGS
cd $WORKSPACE/srcdir/sundials*/cmake/tpl
if [[ "${target}" == *-mingw* ]]; then
    # Work around https://github.com/LLNL/sundials/issues/29
    # When looking for KLU libraries, CMake searches only for import libraries,
    # this patch ensures we look also for shared libraries.
    atomic_patch -p3 $WORKSPACE/srcdir/patches/Sundials_findklu_suffixes.patch
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
    -DLAPACK_WORKS=ON \
    -DBLA_VENDOR="libblastrampoline" \
    ..

cmake --build . --parallel ${nproc}
cmake --install .
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
    # Note: libsundials_generic was renamed to libsundials_core in v7
    LibraryProduct("libsundials_core", :libsundials_core),
]

dependencies = [
    HostBuildDependency("CMake_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("libblastrampoline_jll"),
    Dependency("SuiteSparse_jll"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               preferred_gcc_version = v"6", julia_compat="1.10")
