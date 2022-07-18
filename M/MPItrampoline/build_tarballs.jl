# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MPItrampoline"
version = v"4.2.0"

mpitrampoline_version = v"4.2.0"
mpich_version_str = "4.0.2"
mpiconstants_version = v"1.5.0"
mpiwrapper_version = v"2.8.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/eschnett/MPItrampoline/archive/refs/tags/v$(mpitrampoline_version).tar.gz",
                  "92eaa864fb364752a89752d6962f2d20e248bdf69e433d76417a25cac9b8244b"),
    ArchiveSource("https://github.com/eschnett/MPIconstants/archive/refs/tags/v$(mpiconstants_version).tar.gz",
                  "eee6ae92bb746d3c50ea231aa58607fc5bac373680ff5c45c8ebc10e0b6496b4"),
    ArchiveSource("https://www.mpich.org/static/downloads/$(mpich_version_str)/mpich-$(mpich_version_str).tar.gz",
                  "5a42f1a889d4a2d996c26e48cbf9c595cbf4316c6814f7c181e3320d21dedd42"),
    ArchiveSource("https://github.com/eschnett/MPIwrapper/archive/refs/tags/v$(mpiwrapper_version).tar.gz",
                  "e6fc1c08ad778675e5b58b91b4658b12e3f985c6d4c5c2c3e9ed35986146780e"),
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
    -DMPITRAMPOLINE_DEFAULT_MPIEXEC="@MPITRAMPOLINE_DIR@/bin/mpiwrapperexec" \
    ..
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
else
    export CROSS_F90_ADDRESS_KIND=8
fi
export CROSS_F90_OFFSET_KIND=8
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

# Building with an external hwloc leads to problems loading the
# resulting libraries and executable via MPIwrapper, because this
# happens outside of Julia's control.

# Produce static libraries since these are easier to handle
# downstream. (MPIwrapper doesn't need to find its dependencies.) Also
# make sure that these static libraries can be linked into shared
# libraries.

# Disable OpenCL since it requires the option `-framework OpenCL` on
# macOS, and cmake does not handle this option well. cmake assumes
# that this is one option and one file name and splits them up.

export CFLAGS='-fPIC -DPIC'
export CXXFLAGS='-fPIC -DPIC'
export FFLAGS='-fPIC -DPIC'
export FCFLAGS='-fPIC -DPIC'

if [[ "${target}" == aarch64-apple-* ]]; then
    export FFLAGS="$FFLAGS -fallow-argument-mismatch"
fi

if [[ "${target}" == *-apple-* ]]; then
    # MPICH uses the link options `-flat_namespace` on Darwin. This
    # conflicts with MPItrampoline, which requires the option
    # `-twolevel_namespace`.
    EXTRA_FLAGS+=(--enable-two-level-namespace)
fi

if [[ "${target}" == aarch64-apple-* ]]; then
    EXTRA_FLAGS+=(
        FFLAGS=-fallow-argument-mismatch
        FCFLAGS=-fallow-argument-mismatch
    )
fi

./configure \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-dependency-tracking \
    --docdir=/tmp \
    --enable-shared=no \
    --enable-static=yes \
    --enable-threads=multiple \
    --enable-opencl=no \
    --with-device=ch3 \
    --prefix=${prefix}/lib/mpich \
    "${EXTRA_FLAGS[@]}"

# Remove empty `-l` flags from libtool
# (Why are they there? They should not be.)
# Run the command several times to handle multiple (overlapping) occurrences.
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool

make -j${nproc}
make -j${nproc} install

# Delete duplicate file
if ar t $prefix/lib/mpich/lib/libpmpi.a | grep -q setbotf.o; then
    ar d $prefix/lib/mpich/lib/libmpifort.a setbotf.o
fi

################################################################################
# Install MPIwrapper
################################################################################

cd $WORKSPACE/srcdir/MPIwrapper-*
mkdir build
cd build
# Yes, this is tedious. No, without being this explicit, cmake will
# not properly auto-detect the MPI libraries on Darwin.
if [[ "${target}" == *-apple-* ]]; then
    ext='a'
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_FIND_ROOT_PATH="${prefix}/lib/mpich;${prefix}" \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DBUILD_SHARED_LIBS=ON \
        -DMPI_C_COMPILER=cc \
        -DMPI_CXX_COMPILER=c++ \
        -DMPI_Fortran_COMPILER=gfortran \
        -DMPI_C_LIB_NAMES='mpi;pmpi' \
        -DMPI_CXX_LIB_NAMES='mpicxx;mpi;pmpi' \
        -DMPI_Fortran_LIB_NAMES='mpifort;mpi;pmpi' \
        -DMPI_pmpi_LIBRARY=${prefix}/lib/mpich/lib/libpmpi.${ext} \
        -DMPI_mpi_LIBRARY=${prefix}/lib/mpich/lib/libmpi.${ext} \
        -DMPI_mpicxx_LIBRARY=${prefix}/lib/mpich/lib/libmpicxx.${ext} \
        -DMPI_mpifort_LIBRARY=${prefix}/lib/mpich/lib/libmpifort.${ext} \
        -DMPIEXEC_EXECUTABLE=${prefix}/lib/mpich/bin/mpiexec \
        ..
else
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_FIND_ROOT_PATH="${prefix}/lib/mpich;${prefix}" \
        -DMPIEXEC_EXECUTABLE=${prefix}/lib/mpich/bin/mpiexec \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        ..
fi

cmake --build . --config RelWithDebInfo --parallel $nproc
cmake --build . --config RelWithDebInfo --parallel $nproc --target install

################################################################################
# Install licenses
################################################################################

install_license $WORKSPACE/srcdir/MPItrampoline-*/LICENSE.md $WORKSPACE/srcdir/mpich*/COPYRIGHT
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# MPItrampoline requires `RTLD_DEEPBIND` for `dlopen`, and thus does
# not support musl or BSD.
# FreeBSD: https://reviews.freebsd.org/D24841
platforms = filter(p -> !(Sys.isfreebsd(p) || Sys.iswindows(p) || libc(p) == "musl"), platforms)

platforms = expand_gfortran_versions(platforms)

# Add `mpi+mpitrampoline` platform tag
foreach(p -> (p["mpi"] = "MPItrampoline"), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("mpicc", :mpicc),
    ExecutableProduct("mpicxx", :mpicxx),
    ExecutableProduct("mpifc", :mpifc),
    ExecutableProduct("mpifort", :mpifort),
    ExecutableProduct("mpiexec", :mpiexec),

    # We need to call this library `:libmpi` in Julia so that Julia's
    # `MPI.jl` will find it
    LibraryProduct("libmpitrampoline", :libmpi),

    # MPIconstants
    LibraryProduct("libload_time_mpi_constants", :libload_time_mpi_constants),
    ExecutableProduct("generate_compile_time_mpi_constants", :generate_compile_time_mpi_constants),

    # MPICH
    ExecutableProduct("mpiexec", :mpich_mpiexec, "lib/mpich/bin"),
    
    # MPIwrapper
    ExecutableProduct("mpiwrapperexec", :mpiwrapperexec),
    # `libmpiwrapper` is a plugin, not a library, and thus has the
    # suffix `.so` on macOS. This confuses BinaryBuilder.
    # LibraryProduct("libmpiwrapper", :libmpiwrapper; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"), v"0.5.2"),
    Dependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267"); compat="0.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6")
