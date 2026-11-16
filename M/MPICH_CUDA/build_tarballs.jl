using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))


name = "MPICH_CUDA"
version = v"5.0.2"
ygg_version = v"5.0.3"

sources = [
    ArchiveSource("https://www.mpich.org/static/downloads/$(version)/mpich-$(version).tar.gz",
                  "928c2f18d350a91443fe8024ad01ce2c6009e9c551e0a73e797fc567f119137d"),
    DirectorySource("bundled"),
]

script = raw"""
################################################################################
# Install MPICH
################################################################################

# Enter the funzone
cd ${WORKSPACE}/srcdir/mpich*

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fortran_sentinels_data.patch

# nvcc writes to /tmp, which is a small tmpfs in the sandbox.
export TMPDIR=${WORKSPACE}/tmpdir
mkdir -p ${TMPDIR}

# BinaryBuilder's x86_64 host needs x86_64 CUDA tools to cross compile for aarch64.
# nvvm is inside the nvcc archive before CUDA 13, and in its own archive after.
if [[ "${target}" == aarch64-linux-* ]]; then
    export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
    rm -rf ${prefix}/cuda/bin ${prefix}/cuda/nvvm/bin ${prefix}/cuda/nvvm/lib64
    cp -a ${WORKSPACE}/srcdir/cuda_nvcc-linux-x86_64-*-archive/bin ${prefix}/cuda/bin
    cp -a ${WORKSPACE}/srcdir/*-linux-x86_64-*-archive/nvvm/{bin,lib64} ${prefix}/cuda/nvvm/
fi

export CUDA_HOME=${prefix}/cuda

# Setting `NVCC` stops MPICH's configure scripts from appending their own `-ccbin`.
# CUDA_SM and NVCC_EXTRA_FLAGS are set per platform below.
export NVCC=${CUDA_HOME}/bin/nvcc
export NVCC_PREPEND_FLAGS="-ccbin=${CXX} ${NVCC_EXTRA_FLAGS}"

# MPICH links against `libcuda`, which the SDK only provides as a stub.
# The real library comes from the driver at run time.
# List `lib` explicitly: MPICH's configure does not add `-L.../lib` when it finds it
# as a "word" inside `-L.../lib/stubs`.
export LDFLAGS="-L${CUDA_HOME}/lib -L${CUDA_HOME}/lib/stubs"

# - Do not install doc and man files which contain files which clashing names on
#   case-insensitive file systems:
#   * https://github.com/JuliaPackaging/Yggdrasil/pull/315
#   * https://github.com/JuliaPackaging/Yggdrasil/issues/6344
# - `--enable-fast=all,O3` leads to very long compile times for some
#   files. We need to avoid `alwaysinline`.

configure_flags=(
    --build=${MACHTYPE}
    --disable-dependency-tracking
    --disable-doc
    --enable-fast=ndebug,O3
    --enable-static=no
    --host=${target}
    --prefix=${prefix}
    --with-hwloc=${prefix}
    # `--with-cuda` makes configure fail instead of silently disabling CUDA
    --with-cuda=${CUDA_HOME}
    # Yaksa's default `auto` runs a test program, which fails when cross compiling.
    # (NVCC_PREPEND_FLAGS also lists these architectures.)
    --with-cuda-sm=${CUDA_SM}
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

export CROSS_F90_ADDRESS_KIND=8
export CROSS_F90_OFFSET_KIND=8
export CROSS_F90_INTEGER_KIND=4
export CROSS_F90_INTEGER_MODEL=9
export CROSS_F90_REAL_MODEL=6,37
export CROSS_F90_DOUBLE_MODEL=15,307
export CROSS_F90_ALL_INTEGER_MODELS=2,1,4,2,9,4,18,8,38,16,
export CROSS_F90_INTEGER_MODEL_MAP={2,1,1},{4,2,2},{9,4,4},{18,8,8},{36,16,16},

./configure "${configure_flags[@]}"

# Ensure that CUDA support is actually enabled
grep -q '^#define MPL_HAVE_CUDA 1' src/mpl/include/mplconfig.h
grep -q '^#define HAVE_CUDA 1' src/mpi/datatype/typerep/yaksa/src/frontend/include/yaksa_config.h

# Ensure that int128 and float16 are natively supported
grep -q '#define SIZEOF___INT128' src/include/mpichconf.h
grep -q '#define SIZEOF__FLOAT16' src/include/mpichconf.h

# Remove empty `-l` flags from libtool
# (Why are they there? They should not be.)
# Run the command several times to handle multiple (overlapping) occurrences.
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool

# Build the library
# BinaryBuilder sets `V=true` or `V=false`, but the rule to build `.cu` files
# requires `V` to be empty, `0`, or `1`.
make -j${nproc} V=0

# Install the library
make install V=0

# Install the license
install_license $WORKSPACE/srcdir/mpich*/COPYRIGHT

# Remove everything we may have installed manually
rm -rf ${prefix}/cuda
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

platforms = CUDA.supported_platforms(; min_version = v"11.8")
filter!(p -> arch(p) == "x86_64" || arch(p) == "aarch64", platforms)

# Artifacts are compatible with all newer CUDA minor versions of the same major version.
# Build only for the oldest minor version of each major version.
cuda_key(p) = (arch(p), get(tags(p), "cuda_platform", ""), VersionNumber(p["cuda"]).major)
all_platforms = copy(platforms)
filter!(platforms) do p
    VersionNumber(p["cuda"]) == minimum(VersionNumber(q["cuda"]) for q in all_platforms if cuda_key(q) == cuda_key(p))
end
platforms = expand_gfortran_versions(platforms)

# Add `mpi+mpich` platform tag
for p in platforms
    p["mpi"] = "MPICH"
end

# The libraries require `libcuda` and `libnvidia-ml` from the NVIDIA driver,
# which the build machine might not have.
products = [
    # MPICH
    LibraryProduct("libmpicxx", :libmpicxx; dont_dlopen=true),
    LibraryProduct("libmpifort", :libmpifort; dont_dlopen=true),
    LibraryProduct("libmpi", :libmpi; dont_dlopen=true),
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
    cuda_ver = VersionNumber(platform["cuda"])

    platform_sources = BinaryBuilder.AbstractSource[sources...]

    # Add x86_64 nvcc (and nvvm) to cross compile for aarch64
    if arch(platform) == "aarch64"
        components = ["cuda_nvcc"]
        cuda_ver >= v"13" && push!(components, "libnvvm")
        x86_platform = deepcopy(platform)
        x86_platform["arch"] = "x86_64"
        append!(platform_sources, get_sources("cuda", components;
                                              version=CUDA.full_version(cuda_ver),
                                              platform=x86_platform))
    end

    # Pass the architectures to every nvcc call: MPL compiles its kernels without
    # any. Yaksa adds the same SASS again, which nvcc ignores. Also embed PTX for
    # the newest architecture, so that newer GPUs (supported by newer CUDA minor
    # versions) can JIT-compile it.
    cuda_archs = CUDA.cuda_gpu_archs(platform)
    ptx_arch = maximum(parse.(Int, cuda_archs))
    nvcc_extra_flags = join(["-gencode=arch=compute_$(sm),code=sm_$(sm)" for sm in cuda_archs], " ") *
                       " -gencode=arch=compute_$(ptx_arch),code=compute_$(ptx_arch)"
    # CUDA 11.8 officially supports only GCC <= 11, but we need GCC 12 for `_Float16`
    if cuda_ver < v"12"
        nvcc_extra_flags *= " -allow-unsupported-compiler"
    end
    platform_script = """
        CUDA_SM="$(join(cuda_archs, ","))"
        NVCC_EXTRA_FLAGS="$(nvcc_extra_flags)"
        """ * script

    build_tarballs(ARGS, name, ygg_version, platform_sources, platform_script, [platform],
                   products, [dependencies; cuda_deps];
                   augment_platform_block=augment_platform_block,
                   clang_use_lld=false,
                   julia_compat="1.10",
                   lazy_artifacts=true,
                   preferred_gcc_version=v"12",
                   )
end

# build trigger: 1
