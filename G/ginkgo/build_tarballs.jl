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
    -DCMAKE_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES} \
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

cd .. && mkdir build-stubs && mkdir stubs && cd build-stubs
cmake \
    -DCMAKE_INSTALL_PREFIX=`pwd`/../stubs \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DGINKGO_BUILD_TESTS=OFF \
    -DGINKGO_BUILD_BENCHMARKS=OFF \
    -DGINKGO_BUILD_EXAMPLES=OFF \
    -DGINKGO_DOC_GENERATE_EXAMPLES=OFF \
    -DGINKGO_BUILD_REFERENCE=OFF \
    -DGINKGO_BUILD_OMP=OFF \
    -DGINKGO_BUILD_CUDA=OFF \
    -DGINKGO_BUILD_HIP=OFF \
    -DGINKGO_BUILD_SYCL=OFF \
    -DGINKGO_BUILD_HWLOC=OFF \
    -DGINKGO_BUILD_MPI=OFF \
    -DCMAKE_DISABLE_FIND_PACKAGE_Git=ON \
    -G "Ninja" ../
ninja -j${nproc}
ninja install

mkdir ${prefix}/lib/stubs
cp -P ../stubs/lib/lib* ${prefix}/lib/stubs
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


cuda_archs = Dict(
    v"10.2.89" => "60;61;70;75",
    v"11.4.4" => "60;61;70;75;80;86",
    v"11.5.2" => "60;61;70;75;80;86",
    v"11.6.2" => "60;61;70;75;80;86",
    v"11.7.1" => "60;61;70;75;80;86",
    v"11.8.0" => "60;61;70;75;80;86;89",
    v"12.0.1" => "60;61;70;75;80;86;89;90",
    v"12.1.1" => "60;61;70;75;80;86;89;90",
    v"12.2.2" => "60;61;70;75;80;86;89;90",
    v"12.3.2" => "60;61;70;75;80;86;89;90",
)


for platform in platforms
    should_build_platform(triplet(platform)) || continue

    release = CUDA.full_version(VersionNumber(tags(platform)["cuda"]))

    dependencies = [
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
        BuildDependency(PackageSpec(name="CUDA_full_jll", version=release)),
    ]

    preamble = """
    CUDA_ARCHITECTURES="$(cuda_archs[release])"
    """

    build_tarballs(ARGS, name, version, sources, preamble * script, [platform], products, dependencies; julia_compat="1.6", augment_platform_block, preferred_gcc_version=v"7.1.0")
end
