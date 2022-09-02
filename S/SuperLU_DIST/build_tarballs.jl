# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SuperLU_DIST"
version = v"8.0.1"
superlu_dist_version = v"8.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xiaoyeli/superlu_dist.git", "4459a89719b982dd47af5bb2494a011bb267195f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/superlu_dist*
# allow us to set the name of the shared lib.
sed -i -e 's!OUTPUT_NAME superlu_dist!OUTPUT_NAME "${SUPERLU_OUTPUT_NAME}"!g' SRC/CMakeLists.txt

if [[ "${target}" == *-mingw* ]]; then
    # This is required to ensure that MSMPI can be found by cmake
    export LDFLAGS="-L${libdir} -lmsmpi"
    PLATFLAGS="-DTPL_ENABLE_PARMETISLIB:BOOL=FALSE -DMPI_C_ADDITIONAL_INCLUDE_DIRS=${includedir}"
else
    PLATFLAGS="-DTPL_PARMETIS_INCLUDE_DIRS=${includedir} -DTPL_PARMETIS_LIBRARIES=${libdir}/libparmetis.${dlext};${libdir}/libmetis.${dlext}"
fi

build_superlu_dist()
{
    if [[ "${1}" == "Int64" ]]; then
        INT=64
    else
        INT=32
    fi
    SUPERLU_PREFIX=${libdir}/superlu_dist/Int${INT}
    mkdir -p ${SUPERLU_PREFIX}
    mkdir build-${INT}
    pushd build-${INT}
    cmake \
        -DCMAKE_INSTALL_PREFIX=${SUPERLU_PREFIX} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_STATIC_LIBS=OFF \
        -DTPL_ENABLE_INTERNAL_BLASLIB=OFF \
        -Denable_tests=OFF \
        -Denable_doc=OFF \
        -Denable_single=ON \
        -Denable_double=ON \
        -Denable_complex16=ON \
        -DTPL_BLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
        ${PLATFLAGS} \
        -DCMAKE_C_FLAGS="-std=c99" \
        -DXSDK_INDEX_SIZE=${INT} \
        -DXSDK_ENABLE_Fortran=OFF \
        -DSUPERLU_OUTPUT_NAME="superlu_dist_Int${INT}" \
        -Denable_examples=OFF \
        ..
    make -j${nproc}
    make install
    popd
}
build_superlu_dist Int32
build_superlu_dist Int64
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Excluding Windows due to use of `getline` function, which is non-standard and not provided by MinGW
# per Mose. Will return to it later and attempt to find a solution.
platforms = supported_platforms()

platforms, platform_dependencies = MPI.augment_platforms(platforms)
# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsuperlu_dist_Int32", :libsuperlu_dist_Int32, ["\$libdir/superlu_dist/Int32/lib", "\$libdir/superlu_dist/Int32/bin"]),
    LibraryProduct("libsuperlu_dist_Int64", :libsuperlu_dist_Int64, ["\$libdir/superlu_dist/Int64/lib", "\$libdir/superlu_dist/Int64/bin"])
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency(PackageSpec(name="PARMETIS_jll", uuid="b247a4be-ddc1-5759-8008-7e02fe3dbdaa"); platforms=filter(!Sys.iswindows, platforms)),
    Dependency("METIS_jll"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
# Require GCC 8 to avoid `error: libgfortran.so.4: cannot open shared object file`
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"8")
