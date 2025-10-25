using BinaryBuilder
import Pkg: PackageSpec
using Base.BinaryPlatforms: arch, os, tags

# needed for libjulia_platforms and julia_versions
const YGGDRASIL_DIR = "../../"
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include("make_script.jl")

name = "cupynumeric"
version = v"25.5" # cupynumeric has 05, but Julia doesn't like that
sources = [
    GitSource("https://github.com/nv-legate/cupynumeric.git","cbd9a098b32531d68f1b3007ef86bb8d3859174d"),
    GitSource("https://github.com/MatthewsResearchGroup/tblis.git", "c4f81e08b2827e72335baa7bf91a245f72c43970"),
]


# These should match the legate_jll build_tarballs script
MIN_CUDA_VERSION = v"12.2"
MAX_CUDA_VERSION = v"12.8.999"


cpu_platform = [Platform("x86_64", "linux")]
cuda_platforms = CUDA.supported_platforms(; min_version = MIN_CUDA_VERSION, max_version = MAX_CUDA_VERSION)

all_platforms = [cpu_platform; cuda_platforms]


# for now NO ARM support, tblis doesnt have docs on how to build for arm
filter!(p -> arch(p) == "x86_64", all_platforms)

all_platforms = expand_cxxstring_abis(all_platforms) 
filter!(p -> cxxstring_abi(p) == "cxx11", all_platforms)

# manually mark platforms that could support CUDA, set 
# flag so we know that we do NOT want to install CUDA on this one
for platform in all_platforms
    if CUDA.is_supported(platform) && !haskey(platform, "cuda")
        platform["cuda"] = "none"
    end
end

products = [
    LibraryProduct("libcupynumeric", :libcupynumeric)
] 

dependencies = [
    Dependency("legate_jll"; compat = "=25.5"), # Legate versioning is Year.Month
    # Dependency("CUTENSOR_jll", compat = "2.2"), # supplied via ArchiveSource
    Dependency("OpenBLAS32_jll"),
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = v"3.30.2")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")) 
]

for platform in all_platforms

    should_build_platform(triplet(platform)) || continue

    platform_sources = BinaryBuilder.AbstractSource[sources...]

    _dependencies = copy(dependencies)
    script = get_script(Val{false}())

    if haskey(platform, "cuda") && platform["cuda"] != "none" 

        # cuTensor dependency
        push!(platform_sources, ArchiveSource("https://github.com/JuliaBinaryWrappers/CUTENSOR_jll.jl/releases/download/CUTENSOR-v2.2.0%2B0/CUTENSOR.v2.2.0.x86_64-linux-gnu-cuda+12.0.tar.gz",
                     "1c243b48e189070fefcdd603f87c06fada2d71c911dea7028748ad7a4315b816")
        )

        append!(_dependencies, CUDA.required_dependencies(platform, static_sdk=true))

        cuda_ver = platform["cuda"]

        if arch(platform) == "aarch64"
            push!(platform_sources, CUDA.cuda_nvcc_redist_source(cuda_ver, "x86_64"))
        end

        script = get_script(Val{true}())
    end # else CPU build

    build_tarballs(
        ARGS, name, version, platform_sources, 
        script, [platform], products, _dependencies;
        julia_compat = "1.10", 
        preferred_gcc_version = v"11",
        lazy_artifacts = true, dont_dlopen = true,
        augment_platform_block = CUDA.augment
    )


end
