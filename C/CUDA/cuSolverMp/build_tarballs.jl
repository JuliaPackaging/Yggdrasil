using BinaryBuilder
import BinaryBuilderBase
import Pkg: PackageSpec
using Base.BinaryPlatforms: arch, os, tags

# needed for libjulia_platforms and julia_versions
const YGGDRASIL_DIR = "../../"
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "cuSolverMp"
version = v"0.8.0"

# These should match the legate_jll build_tarballs script
MIN_CUDA_VERSION = v"12.2"
MAX_CUDA_VERSION = v"13.1.999" 

cuda_platforms = CUDA.supported_platforms(; min_version = MIN_CUDA_VERSION, max_version = MAX_CUDA_VERSION)

# for now NO ARM support
filter!(p -> arch(p) == "x86_64", cuda_platforms)

cuda_platforms = expand_cxxstring_abis(cuda_platforms) 
filter!(p -> cxxstring_abi(p) == "cxx11", cuda_platforms)

products = [
    LibraryProduct("libcusolvermp", :libcusolvermp)
] 

dependencies = [Dependency("NCCL_jll"; compat="2.28.9")]

for platform in cuda_platforms

    should_build_platform(triplet(platform)) || continue

    platform_products = BinaryBuilderBase.Product[products...]

    _dependencies = copy(dependencies)
    append!(_dependencies, CUDA.required_dependencies(platform, static_sdk=true))

    cuda_ver = VersionNumber(platform["cuda"])
    var = "cuda$(cuda_ver.major)"

    sources = get_sources(
           "cusolvermp",
           ["libcusolvermp"];
           version=version,
           platform=platform,
           variant=var
        )

    build_tarballs(
        ARGS, name, version, sources, 
        script, [platform], platform_products, _dependencies;
        julia_compat = "1.10", 
        preferred_gcc_version = v"11",
        lazy_artifacts = true, dont_dlopen = true,
        augment_platform_block = CUDA.augment
    )
end


# (base) emeitz@dubliner:/tank/emeitz/libcusolvermp-linux-x86_64-0.8.0.3126_cuda13-archive/lib$ readelf -d libcusolverMp.so | grep NEEDED
#  0x0000000000000001 (NEEDED)             Shared library: [libnccl.so.2]
#  0x0000000000000001 (NEEDED)             Shared library: [libcublas.so.13]
#  0x0000000000000001 (NEEDED)             Shared library: [libcusolver.so.12]
#  0x0000000000000001 (NEEDED)             Shared library: [libcuda.so.1]
#  0x0000000000000001 (NEEDED)             Shared library: [libcublasLt.so.13]
#  0x0000000000000001 (NEEDED)             Shared library: [libcusparse.so.12]
#  0x0000000000000001 (NEEDED)             Shared library: [libnvJitLink.so.13]
#  0x0000000000000001 (NEEDED)             Shared library: [libpthread.so.0]
#  0x0000000000000001 (NEEDED)             Shared library: [libdl.so.2]
#  0x0000000000000001 (NEEDED)             Shared library: [librt.so.1]
#  0x0000000000000001 (NEEDED)             Shared library: [libcudart.so.13]
#  0x0000000000000001 (NEEDED)             Shared library: [libstdc++.so.6]
#  0x0000000000000001 (NEEDED)             Shared library: [libm.so.6]
#  0x0000000000000001 (NEEDED)             Shared library: [libgcc_s.so.1]
#  0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
#  0x0000000000000001 (NEEDED)             Shared library: [ld-linux-x86-64.so.2]