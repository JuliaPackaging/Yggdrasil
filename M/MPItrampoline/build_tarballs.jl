# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MPItrampoline"

mpitrampoline_version = v"6.0.0"
version = mpitrampoline_version
mpich_version_str = "4.1.2"

# Collection of sources required to complete build
sources = [
    # This is really the development version before version 6.0.0
    GitSource("https://github.com/eschnett/MPItrampoline", "7d35a4defa3bc6c0980cddbb8a41fb7191e0a2e1"),
    ArchiveSource("https://www.mpich.org/static/downloads/$(mpich_version_str)/mpich-$(mpich_version_str).tar.gz",
                  "3492e98adab62b597ef0d292fb2459b6123bc80070a8aa0a30be6962075a12f0"),
]

# Bash recipe for building across all platforms
script = raw"""
#TODO ################################################################################
#TODO # Install MPItrampoline
#TODO ################################################################################
#TODO 
#TODO #TODO # When we build libraries linking to MPITrampoline, this library needs to find the
#TODO #TODO # libgfortran it links to.  At runtime this isn't a problem, but during the audit in BB we
#TODO #TODO # need to give a little help to MPITrampoline to find it:
#TODO #TODO # <https://github.com/JuliaPackaging/Yggdrasil/pull/5028#issuecomment-1166388492>.  Note, we
#TODO #TODO # apply this *hack* only when strictly needed, to avoid screwing something else up.
#TODO #TODO if [[ "${target}" == x86_64-linux-gnu* ]]; then
#TODO #TODO     INSTALL_RPATH=(-DCMAKE_INSTALL_RPATH='$ORIGIN')
#TODO #TODO else
#TODO INSTALL_RPATH=()
#TODO #TODO fi
#TODO 
#TODO cd ${WORKSPACE}/srcdir/MPItrampoline*/mpitrampoline
#TODO cmake -B build -S . \
#TODO     -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
#TODO     -DCMAKE_FIND_ROOT_PATH=${prefix} \
#TODO     -DCMAKE_INSTALL_PREFIX=${prefix} \
#TODO     "${INSTALL_RPATH[@]}" \
#TODO     -DBUILD_SHARED_LIBS=ON
#TODO cmake --build build --config Debug --parallel ${nproc}
#TODO cmake --build build --config Debug --parallel ${nproc} --target install

################################################################################
# Install MPICH
################################################################################

cd ${WORKSPACE}/srcdir/mpich*

EXTRA_FLAGS=()
# Define some obscure undocumented variables needed for cross-compiling
# the Fortran bindings.  See for example
# - https://stackoverflow.com/q/56759636/2442087
# - https://github.com/pmodels/mpich/blob/d10400d7a8238dc3c8464184238202ecacfb53c7/doc/installguide/cfile
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

#TODO if [[ "${target}" == i686-linux-musl ]]; then
#TODO     # Our `i686-linux-musl` platform is a bit rotten: it can run C programs,
#TODO     # but not C++ or Fortran.  `configure` runs a C program to determine
#TODO     # whether it's cross-compiling or not, but when it comes to running
#TODO     # Fortran programs, it fails.  In addition, `configure` ignores the
#TODO     # above exported variables if it believes it's doing a native build.
#TODO     # Small hack: edit `configure` script to force `cross_compiling` to be
#TODO     # always "yes".
#TODO     sed -i 's/cross_compiling=no/cross_compiling=yes/g' configure
#TODO     EXTRA_FLAGS+=(ac_cv_sizeof_bool="1")
#TODO fi

# Building with an external hwloc leads to problems loading the
# resulting libraries and executable via MPIwrapper because this
# happens outside of Julia's control.

# Produce static libraries since these are easier to handle
# downstream. (MPIwrapper doesn't need to find its dependencies.) Also
# make sure that these static libraries can be linked into shared
# libraries.

# Disable OpenCL since it requires the option `-framework OpenCL` on
# macOS, and cmake does not handle this option well. cmake assumes
# that this is one option plus one file name and splits them up.

export CFLAGS='-fPIC -DPIC'
export CXXFLAGS='-fPIC -DPIC'
export FFLAGS='-fPIC -DPIC'
export FCFLAGS='-fPIC -DPIC'

if [[ "${target}" == *-apple-* ]]; then
    # MPICH uses the link options `-flat_namespace` on Darwin. This
    # conflicts with MPItrampoline, which requires the option
    # `-twolevel_namespace`.
    EXTRA_FLAGS+=(--enable-two-level-namespace)
fi

#TODO if [[ "${target}" == aarch64-apple-* ]]; then
#TODO     EXTRA_FLAGS+=(
#TODO         FFLAGS=-fallow-argument-mismatch
#TODO         FCFLAGS=-fallow-argument-mismatch
#TODO     )
#TODO fi

# Do not install doc and man files which contain files which clashing names on
# case-insensitive file systems:
# - https://github.com/JuliaPackaging/Yggdrasil/pull/315
# - https://github.com/JuliaPackaging/Yggdrasil/issues/6344
./configure \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-dependency-tracking \
    --docdir=/tmp \
    --mandir=/tmp \
    --enable-shared=no \
    --enable-static=yes \
    --enable-threads=multiple \
    --with-device=ch3 \
    --prefix=${prefix}/lib/mpich \
    "${EXTRA_FLAGS[@]}"

#TODO # Remove empty `-l` flags from libtool
#TODO # (Why are they there? They should not be.)
#TODO # Run the command several times to handle multiple (overlapping) occurrences.
#TODO sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
#TODO sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
#TODO sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool

make -j${nproc}
make -j${nproc} install

#TODO # Delete duplicate file
#TODO if ar t ${prefix}/lib/mpich/lib/libpmpi.a | grep -q setbotf.o; then
#TODO     ar d ${prefix}/lib/mpich/lib/libmpifort.a setbotf.o
#TODO fi

################################################################################
# Install MPIwrapper
################################################################################

cd ${WORKSPACE}/srcdir/MPItrampoline*/mpiwrapper

# We need to be careful to build MPIwrapper against the MPICH we just
# built and installed into `${prefix}/lib/mpich`, and not accidentally
# against the MPItrampoline we built and installed into `${prefix}`
# earlier.

# Yes, this is tedious. No, without being this explicit, cmake will
# not properly auto-detect the MPI libraries on Darwin.
if [[ "${target}" == *-apple-* ]]; then
    ext='a'
    cmake -B build -S . \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_FIND_ROOT_PATH="${prefix}/lib/mpich;${prefix}" \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        "${INSTALL_RPATH[@]}" \
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
        -DMPIEXEC_EXECUTABLE=${prefix}/lib/mpich/bin/mpiexec
else
    cmake -B build -S . \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_FIND_ROOT_PATH="${prefix}/lib/mpich;${prefix}" \
        -DMPIEXEC_EXECUTABLE=${prefix}/lib/mpich/bin/mpiexec \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        "${INSTALL_RPATH[@]}"
fi

cmake --build build --config Debug --parallel ${nproc}
cmake --build build --config Debug --parallel ${nproc} --target install

################################################################################
# Install licenses
################################################################################

install_license ${WORKSPACE}/srcdir/MPItrampoline*/LICENSE.md ${WORKSPACE}/srcdir/mpich*/COPYRIGHT
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

#TODO # MPItrampoline requires `RTLD_DEEPBIND` for `dlopen`, and thus does
#TODO # not support musl or BSD.
#TODO # FreeBSD: https://reviews.freebsd.org/D24841
#TODO platforms = filter(p -> !(Sys.isfreebsd(p) || Sys.iswindows(p) || libc(p) == "musl"), platforms)

platforms = expand_gfortran_versions(platforms)

# Add `mpi+mpitrampoline` platform tag
foreach(p -> (p["mpi"] = "MPItrampoline"), platforms)

# Save time while testing
# TODO: Disable this in production!
platforms = filter(p -> arch(p) == "x86_64" && Sys.islinux(p) && libc(p) == "glibc" && libgfortran_version(p) == v"5", platforms)
@show platforms

# The products that we will ensure are always built
products = [
    ExecutableProduct("mpicc", :mpicc),
    ExecutableProduct("mpicxx", :mpicxx),
    ExecutableProduct("mpifc", :mpifc),
    ExecutableProduct("mpifort", :mpifort),
    # ExecutableProduct("mpiexec", :mpiexec),

    # We need to call this library `:libmpi` in Julia so that Julia's
    # `MPI.jl` will find it
    LibraryProduct("libmpitrampoline", :libmpi),

    # MPICH
    # ExecutableProduct("mpiexec", :mpich_mpiexec, "lib/mpich/bin"),
    ExecutableProduct("mpiexec", :mpiexec, "lib/mpich/bin"),

    # MPIwrapper
    # `libmpiwrapper` is a plugin, not a library, and thus has the
    # suffix `.so` on macOS. This confuses BinaryBuilder.
    # LibraryProduct("libmpiwrapper", :libmpiwrapper; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"), v"0.5.2"),
    Dependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267");
                      compat="0.1", top_level=true),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6")
