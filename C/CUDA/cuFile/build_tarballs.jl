using BinaryBuilder
import BinaryBuilderBase
import Pkg: PackageSpec
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../../../"
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "cuFile"
version = v"1.16.1"

MIN_CUDA_VERSION = v"12.2"
MAX_CUDA_VERSION = v"13.0.999" 

cuda_platforms = CUDA.supported_platforms(; min_version = MIN_CUDA_VERSION, max_version = MAX_CUDA_VERSION)

# for now NO ARM support
filter!(p -> arch(p) == "x86_64", cuda_platforms)

cuda_platforms = expand_cxxstring_abis(cuda_platforms) 
filter!(p -> cxxstring_abi(p) == "cxx11", cuda_platforms)

redist_script = raw"""

cd ${WORKSPACE}/srcdir/libcufile*

install_license LICENSE

# libraries (just copy everything in lib/)
mkdir -p ${libdir}
cp -av lib/* ${libdir}/

# headers
mkdir -p ${includedir}
cp -av include/* ${includedir}/
"""

products = [
    LibraryProduct("libcufile", :libcufile),
    LibraryProduct("libcufile_rdma", :libcufile_rdma)
] 

dependencies = [
    Dependency("rdma_core_jll"), # has libmlx5.so in tarball but not specified as product
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

for platform in cuda_platforms

    should_build_platform(triplet(platform)) || continue

    platform_products = BinaryBuilderBase.Product[products...]
    platform_deps = BinaryBuilderBase.AbstractDependency[dependencies...]

    append!(platform_deps, CUDA.required_dependencies(platform))

    cuda_ver = VersionNumber(platform["cuda"])
    var = "cuda$(cuda_ver.major)"

    sources = get_sources(
                 "cuda",
                 ["libcufile"];
                 version=cuda_ver,
                 platform=platform
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
