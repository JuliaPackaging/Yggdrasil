using BinaryBuilder, Pkg

name = "MPICH"
version = v"3.4.2"

sources = [
    ArchiveSource("https://www.mpich.org/static/downloads/$(version)/mpich-$(version).tar.gz",
                  "5c19bea8b84e8d74cca5f047e82b147ff3fba096144270e3911ad623d6c587bf"),
    ArchiveSource("https://github.com/eschnett/MPIconstants/archive/refs/tags/v1.2.0.tar.gz",
                  "2e658150ffb895b70f1503b4d609460986bb9008fc2e72383102cbcc28535e7e"),
]

script = raw"""
################################################################################
# Install MPICH
################################################################################

# Enter the funzone
cd ${WORKSPACE}/srcdir/mpich*

# if [[ "${target}" == powerpc64le-* ]]; then
    # I don't understand why, but the extra link flags we append in the gfortran
    # wrapper confuse the build system: the rule to build libmpifort has an
    # extra lone `-l` flag, without any library to link to.  The following sed
    # script basically reverts
    # https://github.com/JuliaPackaging/BinaryBuilder.jl/pull/749, so that the
    # extra link flags are not appended to the gfortran wrapper
    sed -i 's/POST_FLAGS+.*/POST_FLAGS=()/g' /opt/bin/${target}*/gfortran
# fi

EXTRA_FLAGS=()
if [[ "${target}" != i686-linux-gnu ]] || [[ "${target}" != x86_64-linux-* ]]; then
    # Define some obscure undocumented variables needed for cross compilation of
    # the Fortran bindings.  See for example
    # * https://stackoverflow.com/q/56759636/2442087
    # * https://github.com/pmodels/mpich/blob/d10400d7a8238dc3c8464184238202ecacfb53c7/doc/installguide/cfile
    export CROSS_F77_SIZEOF_INTEGER=4
    export CROSS_F77_TRUE_VALUE=1
    export CROSS_F77_FALSE_VALUE=0

    export CROSS_F90_ADDRESS_KIND=8
    export CROSS_F90_OFFSET_KIND=8
    export CROSS_F90_INTEGER_KIND=4
    export CROSS_F90_DOUBLE_MODEL=15,307
    export CROSS_F90_REAL_MODEL=6,37

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

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-shared=yes --enable-static=no \
    --with-device=ch3 --disable-dependency-tracking \
    --docdir=/tmp \
    "${EXTRA_FLAGS[@]}"

# Build the library
make -j${nproc}

# Install the library
make install

################################################################################
# Install MPIconstants
################################################################################

cd ${WORKSPACE}/srcdir/MPIconstants*
mkdir build
cd build
# Yes, this is tedious. No, without being this explicit, cmake will
# not properly auto-detect the MPI libraries.
if [ -f ${prefix}/lib/libpmpi.${dlext} ]; then
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_FIND_ROOT_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DBUILD_SHARED_LIBS=ON \
        -DMPI_C_COMPILER=cc \
        -DMPI_C_LIB_NAMES='mpi;pmpi' \
        -DMPI_mpi_LIBRARY=${prefix}/lib/libmpi.${dlext} \
        -DMPI_pmpi_LIBRARY=${prefix}/lib/libpmpi.${dlext} \
        ..
else
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_FIND_ROOT_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DBUILD_SHARED_LIBS=ON \
        -DMPI_C_COMPILER=cc \
        -DMPI_C_LIB_NAMES='mpi' \
        -DMPI_mpi_LIBRARY=${prefix}/lib/libmpi.${dlext} \
        ..
fi

cmake --build . --config RelWithDebInfo --parallel $nproc
cmake --build . --config RelWithDebInfo --parallel $nproc --target install

################################################################################
# Install licenses
################################################################################

install_license $WORKSPACE/srcdir/mpich*/COPYRIGHT $WORKSPACE/srcdir/MPIconstants-*/LICENSE.md
"""

platforms = expand_gfortran_versions(filter!(!Sys.iswindows, supported_platforms(; experimental=true)))

products = [
    # MPICH
    LibraryProduct("libmpicxx", :libmpicxx),
    LibraryProduct("libmpifort", :libmpifort),
    LibraryProduct("libmpi", :libmpi),
    ExecutableProduct("mpiexec", :mpiexec),
    # MPIconstants
    LibraryProduct("libload_time_mpi_constants", :libload_time_mpi_constants),
    ExecutableProduct("generate_compile_time_mpi_constants", :generate_compile_time_mpi_constants),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
