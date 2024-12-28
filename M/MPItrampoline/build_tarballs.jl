# TODO: Investigate this:

# Tim Besard
# Do we have a reliable way to set env vars during the dlopen of a library? __init__ is too late, but IIRC Julia also dlopens libraries as part of deserialization, so it may be tricky.
# Elliot Saba
#   BB2 (come to the talk) will provide lazy loading of libraries (upon first ccall). We then can set environment variables upon init that will be there before dlopen
# :tada:
# Elliot Saba
#   Also, for JLLs, I believe the dlopen occurs during init time, so I think we should be able to make it work now?
# Tim Besard
#   looks like init_library_product from __init__ is the relevant call indeed
# Erik Schnetter
#   nice! thanks for the pointer. using that will make providing MPItrampoline_jll much easier.



# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MPItrampoline"

mpitrampoline_version = v"5.5.0"
version = v"5.5.1"
mpich_version_str = "4.2.3"
mpiconstants_version = v"1.5.0"
mpiwrapper_version = v"2.11.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/eschnett/MPItrampoline", "67292e8b1ac40aa5bd6d0a5dab669da32405a2d7"),
    GitSource("https://github.com/eschnett/MPIconstants", "d2763908c4d69c03f77f5f9ccc546fe635d068cb"),
    ArchiveSource("https://www.mpich.org/static/downloads/$(mpich_version_str)/mpich-$(mpich_version_str).tar.gz",
                  "7a019180c51d1738ad9c5d8d452314de65e828ee240bcb2d1f80de9a65be88a8"),
    GitSource("https://github.com/eschnett/MPIwrapper", "070c4e1b8a98fbe63ea8f84d046effb813c9febb"),
]

# Bash recipe for building across all platforms
script = raw"""

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

if [[ "${target}" == *-apple-* ]]; then
    # MPICH uses the link options `-flat_namespace` on Darwin. This
    # conflicts with MPItrampoline, which requires the option
    # `-twolevel_namespace`.
    EXTRA_FLAGS+=(--enable-two-level-namespace)
fi

# Do not install doc and man files which contain files which clashing names on
# case-insensitive file systems:
# * https://github.com/JuliaPackaging/Yggdrasil/pull/315
# * https://github.com/JuliaPackaging/Yggdrasil/issues/6344
./configure \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-dependency-tracking \
    --disable-doc \
    --enable-shared=no \
    --enable-static=yes \
    --enable-threads=multiple \
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

# We install MPIwrapper before MPItrampoline so that it cannot
# accidentally pick up the wrong MPI headers or libraries.

cd $WORKSPACE/srcdir/MPIwrapper*

EXTRA_FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    EXTRA_FLAGS+=(
        -DMPI_C_LINK_FLAGS='-framework Foundation -framework IOKit'
        -DMPI_CXX_LINK_FLAGS='-framework Foundation -framework IOKit'
        -DMPI_Fortran_LINK_FLAGS='-framework Foundation -framework IOKit'
    )
elif [[ "${target}" == *-freebsd* ]]; then
    EXTRA_FLAGS+=(
        -DMPI_Fortran_LIB_NAMES='mpifort;mpi;gcc;pthread'
        -DMPI_gcc_LIBRARY="/opt/${target}/${target}/sys-root/usr/lib/libgcc.a"
        -DMPI_mpi_LIBRARY="${prefix}/lib/mpich/lib/libmpi.a"
        -DMPI_mpifort_LIBRARY="${prefix}/lib/mpich/lib/libmpifort.a"
        -DMPI_pthread_LIBRARY="/opt/${target}/${target}/sys-root/usr/lib/libpthread.so"
    )
fi
cmake -B build \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_FIND_ROOT_PATH="${prefix}/lib/mpich;${prefix}" \
    -DMPI_HOME=${prefix}/lib/mpich \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    "${INSTALL_RPATH[@]}" \
    "${EXTRA_FLAGS[@]}"

cmake --build build --parallel ${nproc}
cmake --install build

################################################################################
# MPItrampoline
################################################################################

# When we build libraries linking to MPITrampoline, this library needs to find the
# libgfortran it links to.  At runtime this isn't a problem, but during the audit in BB we
# need to give a little help to MPITrampoline to find it:
# <https://github.com/JuliaPackaging/Yggdrasil/pull/5028#issuecomment-1166388492>.  Note, we
# apply this *hack* only when strictly needed, to avoid screwing something else up.
if [[ "${target}" == x86_64-linux-gnu* ]]; then
    INSTALL_RPATH=(-DCMAKE_INSTALL_RPATH='$ORIGIN')
else
    INSTALL_RPATH=()
fi

cd $WORKSPACE/srcdir/MPItrampoline*
cmake -B build \
    -DCMAKE_BUILD_TYPE_TYPE=RelWithDebInfo \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    "${INSTALL_RPATH[@]}" \
    -DBUILD_SHARED_LIBS=ON \
    -DMPITRAMPOLINE_DEFAULT_LIB="@MPITRAMPOLINE_DIR@/lib/libmpiwrapper.so" \
    -DMPITRAMPOLINE_DEFAULT_MPIEXEC="@MPITRAMPOLINE_DIR@/bin/mpiwrapperexec"
cmake --build build --parallel ${nproc}
cmake --install build

# Post-process the compiler wrappers. They remember the original
# compiler used to build MPItrampoline, but this compiler is too
# specific for BinaryBuilder. The compilers should just be `$CC`, `$CXX`,
# `$FC` etc.
sed -i -e 's/^MPITRAMPOLINE_CC=.*$/MPITRAMPOLINE_CC=${MPITRAMPOLINE_CC:-${CC}}/' ${bindir}/mpicc
sed -i -e 's/^MPITRAMPOLINE_CXX=.*$/MPITRAMPOLINE_CXX=${MPITRAMPOLINE_CXX:-${CXX}}/' ${bindir}/mpicxx
sed -i -e 's/^MPITRAMPOLINE_FC=.*$/MPITRAMPOLINE_FC=${MPITRAMPOLINE_FC:-${FC}}/' ${bindir}/mpifc
cp ${bindir}/mpifc ${bindir}/mpifort

################################################################################
# Install MPIconstants
################################################################################

cd ${WORKSPACE}/srcdir/MPIconstants*
cmake -B build \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    "${INSTALL_RPATH[@]}" \
    -DBUILD_SHARED_LIBS=ON
cmake --build build --parallel ${nproc}
cmake --install build

################################################################################
# Install licenses
################################################################################

install_license $WORKSPACE/srcdir/MPItrampoline*/LICENSE.md $WORKSPACE/srcdir/mpich*/COPYRIGHT
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# MPItrampoline requires `RTLD_DEEPBIND` for `dlopen`, and thus does
# not support musl.
platforms = filter(p -> !(Sys.iswindows(p) || libc(p) == "musl"), platforms)

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
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267");
               compat="0.1", top_level=true),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We use GCC 5 to ensure Fortran module files are readable by all `libgfortran3` architectures. GCC 4 would use an older format.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", clang_use_lld=false, preferred_gcc_version=v"5")

# Build trigger: 1
