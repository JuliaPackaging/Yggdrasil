using BinaryBuilder
import Pkg: PackageSpec
using Base.BinaryPlatforms: arch, os, tags

# needed for libjulia_platforms and julia_versions
const YGGDRASIL_DIR = "../../"
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include("make_script.jl")

name = "cupynumeric"
version = v"26.01"
sources = [
    GitSource("https://github.com/nv-legate/cupynumeric.git","ae1c787828a9327ad00a076739706f41d196a043"),
    GitSource("https://github.com/MatthewsResearchGroup/tblis.git", "c4f81e08b2827e72335baa7bf91a245f72c43970"),
    FileSource("https://repo.anaconda.com/miniconda/Miniconda3-py311_24.3.0-0-Linux-x86_64.sh", 
                "4da8dde69eca0d9bc31420349a204851bfa2a1c87aeb87fe0c05517797edaac4", "miniconda.sh"),    
]


# These should match the legate_jll build_tarballs script
MIN_CUDA_VERSION = v"13.0"
MAX_CUDA_VERSION = v"13.0.999" # none of the dependency JLLs have 13.1 builds rn


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
    Dependency("legate_jll"; compat = "~26.01"), # Legate versioning is Year.Month
    # Dependency("CUTENSOR_jll", compat = "2.2"), # supplied via ArchiveSource
    Dependency("OpenBLAS32_jll"),
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = "3.31.9")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")) 
]

for platform in all_platforms

    should_build_platform(triplet(platform)) || continue

    platform_sources = BinaryBuilder.AbstractSource[sources...]

    _dependencies = copy(dependencies)
    script = get_script(Val{false}())

    if haskey(platform, "cuda") && platform["cuda"] != "none" 

        # cuTensor dependency
        push!(platform_sources, ArchiveSource("https://github.com/JuliaBinaryWrappers/CUTENSOR_jll.jl/releases/download/CUTENSOR-v2.3.1%2B0/CUTENSOR.v2.3.1.x86_64-linux-gnu-cuda+13.0.tar.gz",
                     "bb9d29e92522d4867dcd5124dfb9151cc40eb87f8a7772dd0509bd344e393abf")
        )

        append!(_dependencies, CUDA.required_dependencies(platform, static_sdk=true))

        cuda_ver = platform["cuda"]

        if arch(platform) == "aarch64"
            push!(platform_sources, CUDA.cuda_nvcc_redist_source(cuda_ver, "x86_64"))
        end

        script = get_script(Val{true}())
    end # else CPU-only build

    build_tarballs(
        ARGS, name, version, platform_sources, 
        script, [platform], products, _dependencies;
        julia_compat = "1.10", 
        preferred_gcc_version = v"11",
        lazy_artifacts = true, dont_dlopen = true,
        augment_platform_block = CUDA.augment
    )

end
