# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase
using Base.BinaryPlatforms

using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "ginkgo"
version = v"1.6.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/youwuyou/ginkgo.git", "c4128a21b1114bedfc19153a9508b2bd3b54954f")
]

# Bash recipe for building across all platforms
script = raw"""
# nvcc writes to /tmp, which is a small tmpfs in our sandbox.
# make it use the workspace instead
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}
export PATH=$PATH:${prefix}/cuda/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${prefix}/cuda/lib64
export CUDA_HOME=${prefix}/cuda

cd $WORKSPACE/srcdir/ginkgo/
rm -rf .git
mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_CUDA_COMPILER=${prefix}/cuda/bin/nvcc \
    -DCMAKE_CUDA_ARCHITECTURES='50;60;70;75;80;86' \
    -DGINKGO_BUILD_TESTS=OFF \
    -DGINKGO_BUILD_BENCHMARKS=OFF \
    -DGINKGO_BUILD_EXAMPLES=OFF \
    -DGINKGO_DOC_GENERATE_EXAMPLES=OFF \
    -DGINKGO_BUILD_REFERENCE=ON \
    -DGINKGO_BUILD_OMP=ON \
    -DGINKGO_BUILD_CUDA=ON \
    -DGINKGO_BUILD_HIP=OFF \
    -DGINKGO_BUILD_SYCL=OFF \
    -DGINKGO_BUILD_HWLOC=OFF \
    -DGINKGO_BUILD_MPI=OFF \
    -DCMAKE_DISABLE_FIND_PACKAGE_Git=ON \
    -G "Ninja" ../
ninja -j${nproc} 
ninja install
"""

augment_platform_block = CUDA.augment

platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)

# some platforms need a newer glibc, because the default one is too old
glibc_platforms = filter(platforms) do p
    libc(p) == "glibc" && proc_family(p) in ["intel", "power"]
end


# The products that we will ensure are always built
products = [
    LibraryProduct("libginkgo", :libginkgo),
    LibraryProduct("libginkgo_device", :libginkgo_device),
    LibraryProduct("libginkgo_cuda", :libginkgo_cuda),
    LibraryProduct("libginkgo_reference", :libginkgo_reference),
    LibraryProduct("libginkgo_omp", :libginkgo_omp),
    LibraryProduct("libginkgo_dpcpp", :libginkgo_dpcpp),
    LibraryProduct("libginkgo_hip", :libginkgo_hip)
]


function required_dependencies(platform; static_sdk=false)
    dependencies = Dependency[]
    if !haskey(tags(platform), "cuda") || tags(platform)["cuda"] == "none"
        return BinaryBuilder.AbstractDependency[]
    end
    release = VersionNumber(tags(platform)["cuda"])
    deps = BinaryBuilder.AbstractDependency[
        BuildDependency(PackageSpec(name="CUDA_full_jll", version=CUDA.full_version(release))),
        RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll"))
    ]

    if static_sdk
        push!(deps, BuildDependency(PackageSpec(name="CUDA_SDK_static_jll", version=CUDA.full_version(release))))
    end

    return deps
end


for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = required_dependencies(platform)
    "cuda_deps = CUDA.required_dependencies(platform; static_sdk=true)"

    dependencies = [
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    ]

    build_tarballs(ARGS, name, version, sources, script, [platform], products, [dependencies; cuda_deps]; julia_compat="1.6", augment_platform_block, preferred_gcc_version=v"7.1.0")
end
