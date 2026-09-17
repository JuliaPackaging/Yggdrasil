using BinaryBuilder
import BinaryBuilderBase
import Pkg: PackageSpec
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../../../"
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "cuSolverMp"
version = v"0.8.0"

MIN_CUDA_VERSION = v"12.2"
MAX_CUDA_VERSION = v"13.0.999" 

cuda_platforms = CUDA.supported_platforms(; min_version = MIN_CUDA_VERSION, max_version = MAX_CUDA_VERSION)

# for now NO ARM support
filter!(p -> arch(p) == "x86_64", cuda_platforms)

cuda_platforms = expand_cxxstring_abis(cuda_platforms) 
filter!(p -> cxxstring_abi(p) == "cxx11", cuda_platforms)

redist_script = raw"""

cd ${WORKSPACE}/srcdir/libcusolvermp*

install_license LICENSE

# libraries (just copy everything in lib/)
mkdir -p ${libdir}
cp -av lib/* ${libdir}/

# headers
mkdir -p ${includedir}
cp -av include/* ${includedir}/
"""

products = [
    LibraryProduct("libcusolverMp", :libcusolvermp)
] 

dependencies = [Dependency("NCCL_jll"; compat="2.28.9")]

for platform in cuda_platforms

    should_build_platform(triplet(platform)) || continue

    platform_products = BinaryBuilderBase.Product[products...]
    platform_deps = BinaryBuilderBase.AbstractDependency[dependencies...]

    append!(platform_deps, CUDA.required_dependencies(platform))

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
        ARGS, name, version, sources, redist_script,
        [platform], platform_products, platform_deps;
        julia_compat = "1.10", 
        preferred_gcc_version = v"11",
        lazy_artifacts = true, dont_dlopen = true,
        augment_platform_block = CUDA.augment
    )
end
