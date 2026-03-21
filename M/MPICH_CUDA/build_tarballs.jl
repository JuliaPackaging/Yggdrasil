using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))


name = "MPICH_CUDA"
version = v"5.0.0"

sources = [
    ArchiveSource("https://www.mpich.org/static/downloads/$(version)/mpich-$(version).tar.gz",
                  "e9350e32224283e95311f22134f36c98e3cd1c665d17fae20a6cc92ed3cffe11"),
]

script = raw"""
################################################################################
# Install MPICH
################################################################################

# Enter the funzone
cd ${WORKSPACE}/srcdir/mpich*

# Necessary operations to cross compile CUDA from x86_64 to aarch64
if [[ "${target}" == aarch64-linux-* ]]; then

    # Add /usr/lib/csl-musl-x86_64 to LD_LIBRARY_PATH to be able to use host nvcc
    export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
   
    # Make sure we use host CUDA executable by copying from the x86_64 CUDA redist
    NVCC_DIR=(/workspace/srcdir/cuda_nvcc-*-archive)
    rm -rf ${prefix}/cuda/bin
    cp -r ${NVCC_DIR}/bin ${prefix}/cuda/bin
   
    rm -rf ${prefix}/cuda/nvvm/bin
    if [ -d ${NVCC_DIR}/cuda/nvvm ]; then
        # Only copy nvvm if it exists. (CUDA 13 requires a separate download for nvvm.)
        cp -r ${NVCC_DIR}/nvvm/bin ${prefix}/cuda/nvvm/bin
    fi

    export NVCC_PREPEND_FLAGS="-ccbin='${CXX}'"
fi

export CUDA_HOME=${prefix}/cuda
export CUDACXX=${CUDA_HOME}/bin/nvcc
export CUDA_LIB=${CUDA_HOME}/lib
export CUDA_INCLUDE=${CUDA_HOME}/include

# - Do not install doc and man files which contain files which clashing names on
#   case-insensitive file systems:
#   * https://github.com/JuliaPackaging/Yggdrasil/pull/315
#   * https://github.com/JuliaPackaging/Yggdrasil/issues/6344
# - `--enable-fast=all,O3` leads to very long compile times for the
#   file `src/mpi/coll/mpir_coll.c`. It seems we need to avoid
#   `alwaysinline`.

configure_flags=(
    --build=${MACHTYPE}
    --disable-dependency-tracking
    --disable-doc
    --enable-fast=ndebug,O3
    --enable-static=no
    --host=${target}
    --prefix=${prefix}
    --with-device=ch4
    --with-hwloc=${prefix}
    --with-cuda-include=${CUDA_INCLUDE}
    --with-cuda-lib=${CUDA_LIB}
)

# Define some obscure undocumented variables needed for cross compilation of
# the Fortran bindings.  See for example
# * https://stackoverflow.com/q/56759636/2442087
# * https://github.com/pmodels/mpich/blob/d10400d7a8238dc3c8464184238202ecacfb53c7/doc/installguide/cfile
export CROSS_F77_SIZEOF_INTEGER=4
export CROSS_F77_SIZEOF_REAL=4
export CROSS_F77_SIZEOF_DOUBLE_PRECISION=8
export CROSS_F77_SIZEOF_LOGICAL=4
export CROSS_F77_TRUE_VALUE=1
export CROSS_F77_FALSE_VALUE=0

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

./configure "${configure_flags[@]}"

# Ensure that int128 and float16 are natively supported (where possible)
if [[ ${nbits} == 64 ]]; then
    grep -q '#define SIZEOF___INT128' src/include/mpichconf.h
fi
if [[ ${target} != x86_64-apple* ]]; then
    grep -q '#define SIZEOF__FLOAT16' src/include/mpichconf.h
fi

# Remove empty `-l` flags from libtool
# (Why are they there? They should not be.)
# Run the command several times to handle multiple (overlapping) occurrences.
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool

# Build the library
make -j${nproc}

# Install the library
make install

# Install the license
install_license $WORKSPACE/srcdir/mpich*/COPYRIGHT

# Remove everything we may have installed manually
rm -rf ${prefix}/cuda/bin
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(replace(CUDA.augment, "function augment_platform!" => "function augment_cuda!"))
    $(MPI.augment)
    function augment_platform!(platform::Platform)
        augment_cuda!(platform)
        augment_mpi!(platform)
    end
    """

platforms = CUDA.supported_platforms(; min_version = v"11.8", max_version=v"13.1.999")
filter!(p -> arch(p) == "x86_64" || arch(p) == "aarch64", platforms)
platforms = expand_gfortran_versions(platforms)

# Add `mpi+mpich` platform tag
for p in platforms
    p["mpi"] = "MPICH"
end

products = [
    # MPICH
    LibraryProduct("libmpicxx", :libmpicxx),
    LibraryProduct("libmpifort", :libmpifort),
    LibraryProduct("libmpi", :libmpi),
    ExecutableProduct("mpiexec", :mpiexec),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("Hwloc_jll"; compat="2.12.2"),
    RuntimeDependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267");
                      compat="0.1", top_level=true),
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)
    cuda_ver = platform["cuda"]

    platform_sources = BinaryBuilder.AbstractSource[sources...]

    # Add x86_64 CUDA_SDK to cross compile for aarch64
    if arch(platform) == "aarch64"
        push!(platform_sources, CUDA.cuda_nvcc_redist_source(cuda_ver, "x86_64"))
    end

    build_tarballs(ARGS, name, version, platform_sources, script, [platform],
                   products, [dependencies; cuda_deps];
                   augment_platform_block=augment_platform_block,
                   clang_use_lld=false,
                   julia_compat="1.10",
                   preferred_gcc_version=v"12",
                   )
end
