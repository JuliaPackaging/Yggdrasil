# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MPItrampoline"
version = v"2.6.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/eschnett/MPItrampoline/archive/refs/tags/v$(version).tar.gz",
                  "5425085f4b8772990b28a643b7dfc7ac37a399ee35ffa3d6113a06e5b508dfac"),
    ArchiveSource("https://github.com/eschnett/MPIconstants/archive/refs/tags/v1.4.0.tar.gz",
                  "610d816c22cd05e16e17371c6384e0b6f9d3a2bdcb311824d0d40790812882fc"),

    # TODO: Split MPICH and MPIwrapper out into a separate package
    # Idea 1: Add a flag to MPItrampoline to not initialize itself
    #     during initialization. Instead, something else must call
    #     MPItrampoline's initialization function -- early enough,
    #     i.e. still during load time.
    # Idea 2: Don't be a plugin. Rely solely on ELF interposing and
    #     RTLD_DEEPBIND. This would be really cool; think about it
    #     more.
    ArchiveSource("https://www.mpich.org/static/downloads/3.4.2/mpich-3.4.2.tar.gz",
                  "5c19bea8b84e8d74cca5f047e82b147ff3fba096144270e3911ad623d6c587bf"),
    ArchiveSource("https://github.com/eschnett/MPIwrapper/archive/refs/tags/v2.2.0.tar.gz",
                  "9cc9cda6f09288b8694a82cb3a64cf8457e408eee01a612e669fee749c1cb0b8"),
]

# Bash recipe for building across all platforms
script = raw"""
################################################################################
# MPItrampoline
################################################################################

cd $WORKSPACE/srcdir/MPItrampoline-*
mkdir build
cd build
cmake \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DBUILD_SHARED_LIBS=ON \
    -DMPITRAMPOLINE_DEFAULT_LIB="@MPITRAMPOLINE_DIR@/lib/libmpiwrapper.so" \
    -DMPITRAMPOLINE_DEFAULT_PRELOAD="@MPITRAMPOLINE_DIR@/lib/mpich/lib/libmpi.${dlext}:@MPITRAMPOLINE_DIR@/lib/mpich/lib/libmpicxx.${dlext}:@MPITRAMPOLINE_DIR@/lib/mpich/lib/libmpifort.${dlext}" \
    ..
## # Delay initializing MPItrampoline so that we can set an environment variable in Julia pointing to the wrapped MPI library
## false
## # NOTE: We cannot do this since this would delay initialization until after PETSc etc. initialized themselves.
## # Use an intermediate library, shipped with the wrapped MPI library, loaded by Julia by default, capturing its path,
## # setting a global variable.
## cmake \
##     -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
##     -DCMAKE_FIND_ROOT_PATH=$prefix \
##     -DCMAKE_INSTALL_PREFIX=$prefix \
##     -DBUILD_SHARED_LIBS=ON \
##     -DMPITRAMPOLINE_DELAY_INIT=1 \
##     ..
cmake --build . --config RelWithDebInfo --parallel $nproc
cmake --build . --config RelWithDebInfo --parallel $nproc --target install

################################################################################
# Install MPIconstants
################################################################################

cd ${WORKSPACE}/srcdir/MPIconstants*
mkdir build
cd build

cmake \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DBUILD_SHARED_LIBS=ON \
    ..

cmake --build . --config RelWithDebInfo --parallel $nproc
cmake --build . --config RelWithDebInfo --parallel $nproc --target install

################################################################################
# Install MPICH
################################################################################

cd ${WORKSPACE}/srcdir/mpich*

EXTRA_FLAGS=()
if [[ "${target}" != i686-linux-gnu ]] || [[ "${target}" != x86_64-linux-* ]]; then
    # Define some obscure undocumented variables needed for cross compilation of
    # the Fortran bindings.  See for example
    # * https://stackoverflow.com/q/56759636/2442087
    # * https://github.com/pmodels/mpich/blob/d10400d7a8238dc3c8464184238202ecacfb53c7/doc/installguide/cfile
    export CROSS_F77_SIZEOF_INTEGER=4
    export CROSS_F77_SIZEOF_REAL=4
    export CROSS_F77_SIZEOF_DOUBLE_PRECISION=8
    export CROSS_F77_FALSE_VALUE=0
    export CROSS_F77_TRUE_VALUE=1

    if [[ ${nbits} == 32 ]]; then
        export CROSS_F90_ADDRESS_KIND=4
        export CROSS_F90_OFFSET_KIND=4
    else
        export CROSS_F90_ADDRESS_KIND=8
        export CROSS_F90_OFFSET_KIND=8
    fi
    export CROSS_F90_INTEGER_KIND=4
    export CROSS_F90_INTEGER_MODEL=9
    export CROSS_F90_REAL_MODEL=6,37
    export CROSS_F90_DOUBLE_MODEL=15,307
    export CROSS_F90_ALL_INTEGER_MODELS=2,1,4,2,9,4,18,8,
    export CROSS_F90_INTEGER_MODEL_MAP={2,1,1},{4,2,2},{9,4,4},{18,8,8},

    if [[ "${target}" == i686-linux-musl ]]; then
        # Our `i686-linux-musl` platform is a bit rotten: it can run C programs,
        # but not C++ or Fortran.  `configure` runs a C program to determine
        # whether it's cross-compiling or not, but when it comes to running
        # Fortran programs, it fails.  In addition, `configure` ignores the
        # above exported variables if it believes it's doing a native build.
        # Small hack: edit `configure` script to force `cross_compiling` to be
        # always "yes".
        sed -i 's/cross_compiling=no/cross_compiling=yes/g' configure
        EXTRA_FLAGS+=(ac_cv_sizeof_bool="1")
    fi
fi

if [[ "${target}" == aarch64-apple-* ]]; then
    export FFLAGS=-fallow-argument-mismatch
fi

if [[ "${target}" == *-apple-* ]]; then
    # MPICH uses the link options `-flat_namespace` on Darwin. This
    # conflicts with MPItrampoline, which requires the option
    # `-twolevel_namespace`.
    EXTRA_FLAGS+=(--enable-two-level-namespace)
fi

# Building with hwloc leads to problems loading the resulting
# libraries and executable via MPIwrapper, because this happens
# outside of Julia's control

# # Remove -Wl,-commons,use_dylibs
# sed -i 's/-Wl,-commons,use_dylibs//g' configure

./configure \
    --build=${MACHTYPE} \
    --disable-dependency-tracking \
    --docdir=/tmp \
    --enable-shared=yes \
    --enable-static=yes \
    --host=${target} \
    --prefix=${prefix}/lib/mpich \
    --with-device=ch3 \
    "${EXTRA_FLAGS[@]}"

# Remove empty `-l` flags from libtool
# (Why are they there? They should not be.)
# Run the command several times to handle multiple (overlapping) occurrences.
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool

make -j${nproc}
make -j${nproc} install

################################################################################
# Install MPIwrapper
################################################################################

cd $WORKSPACE/srcdir/MPIwrapper-*
mkdir build
cd build
# Yes, this is tedious. No, without being this explicit, cmake will
# not properly auto-detect the MPI libraries.
if [ -f ${prefix}/lib/mpich/lib/libpmpi.${dlext} ]; then
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_FIND_ROOT_PATH="${prefix}/lib/mpich;${prefix}" \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DBUILD_SHARED_LIBS=ON \
        -DMPI_C_COMPILER=cc \
        -DMPI_CXX_COMPILER=c++ \
        -DMPI_Fortran_COMPILER=gfortran \
        -DMPI_CXX_LIB_NAMES='mpicxx;mpi;pmpi' \
        -DMPI_Fortran_LIB_NAMES='mpifort;mpi;pmpi' \
        -DMPI_mpi_LIBRARY=${prefix}/lib/mpich/lib/libmpi.${dlext} \
        -DMPI_mpicxx_LIBRARY=${prefix}/lib/mpich/lib/libmpicxx.${dlext} \
        -DMPI_mpifort_LIBRARY=${prefix}/lib/mpich/lib/libmpifort.${dlext} \
        -DMPI_pmpi_LIBRARY=${prefix}/lib/mpich/lib/libpmpi.${dlext} \
        -DMPIEXEC_EXECUTABLE=${prefix}/lib/mpich/bin/mpiexec \
        ..
else
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_FIND_ROOT_PATH="${prefix}/lib/mpich;${prefix}" \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DBUILD_SHARED_LIBS=ON \
        -DMPI_C_COMPILER=cc \
        -DMPI_CXX_COMPILER=c++ \
        -DMPI_Fortran_COMPILER=gfortran \
        -DMPI_CXX_LIB_NAMES='mpicxx;mpi' \
        -DMPI_Fortran_LIB_NAMES='mpifort;mpi' \
        -DMPI_mpi_LIBRARY=${prefix}/lib/mpich/lib/libmpi.${dlext} \
        -DMPI_mpicxx_LIBRARY=${prefix}/lib/mpich/lib/libmpicxx.${dlext} \
        -DMPI_mpifort_LIBRARY=${prefix}/lib/mpich/lib/libmpifort.${dlext} \
        -DMPIEXEC_EXECUTABLE=${prefix}/lib/mpich/bin/mpiexec \
        ..
fi

cmake --build . --config RelWithDebInfo --parallel $nproc
cmake --build . --config RelWithDebInfo --parallel $nproc --target install

################################################################################
# Install licenses
################################################################################

install_license $WORKSPACE/srcdir/MPItrampoline-*/LICENSE.md $WORKSPACE/srcdir/mpich*/COPYRIGHT
## install_license $WORKSPACE/srcdir/MPItrampoline-*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# MPItrampoline requires `RTLD_DEEPBIND` for `dlopen`,
# and thus does not support musl or BSD.
# FreeBSD: https://reviews.freebsd.org/D24841
platforms = filter(p -> !(Sys.iswindows(p) || libc(p) == "musl"), platforms)
platforms = filter(!Sys.isfreebsd, platforms)
platforms = expand_gfortran_versions(platforms)
# libgfortran3 does not support `!GCC$ ATTRIBUTES NO_ARG_CHECK`. (We
# could in principle build without Fortran support there.)
platforms = filter(p -> libgfortran_version(p) ≠ v"3", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("mpicc", :mpicc),
    ExecutableProduct("mpicxx", :mpicxx),
    ExecutableProduct("mpifc", :mpifc),
    ExecutableProduct("mpifort", :mpifort),
    ExecutableProduct("mpiexec", :mpiexec),

    # We need to call this library `:libmpi` in Julia so that Julia's
    # `MPI.jl` will find it
    LibraryProduct("libmpi", :libmpi),
    LibraryProduct("libmpifort", :libmpifort),

    # MPIconstants
    LibraryProduct("libload_time_mpi_constants", :libload_time_mpi_constants),
    ExecutableProduct("generate_compile_time_mpi_constants", :generate_compile_time_mpi_constants),

    # MPICH
    ExecutableProduct("mpiexec", :mpich_mpiexec, "lib/mpich/bin"),
    # Note the `dont_dlopen=true` below. Without these, Julia would
    # load these libraries automatically into the global namespace,
    # conflicting with MPItrampoline. These settings are also why we
    # can't reuse `MPICH_jll`.
    LibraryProduct("libmpi", :mpich_libmpi, ["lib/mpich/lib"]; dont_dlopen=true),
    LibraryProduct("libmpicxx", :mpich_libmpicxx, ["lib/mpich/lib"]; dont_dlopen=true),
    LibraryProduct("libmpifort", :mpich_libmpifort, ["lib/mpich/lib"]; dont_dlopen=true),
    LibraryProduct("libpmpi", :mpich_libmpi, ["lib/mpich/lib"]; dont_dlopen=true),
    
    # MPIwrapper
    ExecutableProduct("mpiwrapperexec", :mpiwrapperexec),
    # `libmpiwrapper` is a plugin, not a library, and thus has the
    # suffix `.so` on macOS. This confuses BinaryBuilder.
    # LibraryProduct("libmpiwrapper", :libmpiwrapper; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
