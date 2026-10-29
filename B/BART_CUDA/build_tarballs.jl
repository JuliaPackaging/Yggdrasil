using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "BART_CUDA"
version = v"1.0.0"
sources = [
    GitSource("https://codeberg.org/mrirecon/bart.git", "37f3c5f0feaf0a19a7fca85c926ad74101f4a034"),
    DirectorySource("./bundled"),
]

script = raw"""
glibc_root=$(dirname $(dirname $(dirname $(realpath "${prefix}/usr/include/threads.h"))))
rsync --archive "${glibc_root}/" "/opt/${target}/${target}/sys-root/"

# nvcc otherwise uses the sandbox's small /tmp filesystem.
export TMPDIR=${WORKSPACE}/tmpdir
mkdir -v ${TMPDIR}
cd ${WORKSPACE}/srcdir/bart
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cufft-zero-workspace.patch # Fix BART GPU reconstruction crash with CUDA 13.

${host_bindir}/make -j${nproc} \
    AR="${target}-ar" AR_LOCK_NEEDED=0 \
    CUDA=1 CUDNN=0 CUDA_BASE="${prefix}/cuda" CUDA_LIB=lib \
    GPUARCH_FLAGS="${GPUARCH_FLAGS}" \
    FFTW_BASE="${prefix}" FFTW_L="-lfftw3f" \
    BLAS_BASE="${prefix}" BLAS_L="-lopenblas" \
    LDFLAGS="-L${libdir} -fopenmp" \
    OPT="-O2 -ffp-contract=off" bart
git diff --check
install -Dvm755 bart "${bindir}/bart"
install_license LICENSE
"""

# One baseline per CUDA major; CUDA.augment accepts newer compatible minor releases.
platforms = CUDA.supported_platforms(; min_version=v"12.1", max_version=v"13.0.2")
# Other host architectures need a separate nvcc cross-compilation setup.
filter!(p -> arch(p) == "x86_64" && p["cuda"] in ("12.1", "13.0"), platforms)

products = [ExecutableProduct("bart", :bart)]
dependencies = [
    HostBuildDependency(PackageSpec(name="GNUMake_jll", version=v"4.4.1+0")),
    # BART's C11 thread functions require a newer glibc sysroot.
    BuildDependency(PackageSpec(name="Glibc_jll", version=v"2.34.0+1")),
    Dependency("FFTW_jll"; compat="3.3.11"),
    Dependency("OpenBLAS32_jll"; compat="0.3.23"),
    Dependency("libpng_jll"; compat="1.6.43"),
    Dependency("CompilerSupportLibraries_jll"; compat="1.0.5"),
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue
    gpu_archs = CUDA.cuda_gpu_archs(platform)
    gpu_flags = ["-gencode=arch=compute_$sm,code=sm_$sm" for sm in gpu_archs]
    push!(gpu_flags, "-gencode=arch=compute_$(last(gpu_archs)),code=compute_$(last(gpu_archs))")
    platform_script = "GPUARCH_FLAGS=\"$(join(gpu_flags, " "))\"\n" * script

    build_tarballs(ARGS, name, version, sources, platform_script, [platform], products,
                   [dependencies; CUDA.required_dependencies(platform)];
                   preferred_gcc_version=v"12", julia_compat="1.10",
                   augment_platform_block=CUDA.augment, lazy_artifacts=true, dont_dlopen=true)
end
