using BinaryBuilder, Pkg

# needed for libjulia_platforms and julia_versions
const YGGDRASIL_DIR = "../../"
include(joinpath(YGGDRASIL_DIR, "L", "libjulia", "common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include("make_script.jl")

name = "legate_jl_wrapper"
version = v"25.5.1" # legate has 05, but Julia doesn't like that
sources = [
    GitSource("https://github.com/JuliaLegate/legate_jl_wrapper.git","b45876b1a766083cd95f10ffd85652af6150acfe"),
]

MIN_JULIA_VERSION = v"1.10"
MAX_JULIA_VERSION = v"1.11.999"

# These should match the legate_jll build_tarballs script
MIN_CUDA_VERSION = v"12.2"
MAX_CUDA_VERSION = v"12.8.999"


julia_versions = filter!(v -> v >= MIN_JULIA_VERSION && v <= MAX_JULIA_VERSION , julia_versions)
cpu_platform = [Platform("x86_64", "linux")]
cuda_platforms = CUDA.supported_platforms(; min_version = MIN_CUDA_VERSION, max_version = MAX_CUDA_VERSION)
all_platforms = [cpu_platform; cuda_platforms]

platforms = AbstractPlatform[]

# Create all combos of CUDA + Julia Versions...so many builds :( 
for p in all_platforms
    for v in julia_versions
        new_p = deepcopy(p)
        new_p["julia_version"] = string(v)
        push!(platforms, new_p)
    end
end

for platform in platforms
    if CUDA.is_supported(platform) && !haskey(platform, "cuda")
        platform["cuda"] = "none"
    end
end

platforms = expand_cxxstring_abis(platforms) 
platforms = filter!(p -> cxxstring_abi(p) == "cxx11", platforms)

products = [
    LibraryProduct("liblegate_jl_wrapper", :liblegate_jl_wrapper)
] 


dependencies = [
    Dependency("legate_jll"; compat = "=25.5"), # Legate versioning is Year.Month
    Dependency("libcxxwrap_julia_jll"; compat="0.14.3"),
    BuildDependency("libjulia_jll"),
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = v"3.30.2")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")) 
]

for platform in platforms

    should_build_platform(triplet(platform)) || continue

    _dependencies = copy(dependencies)
    script = get_script(Val{false}())

    platform_sources = BinaryBuilder.AbstractSource[sources...]


    if haskey(platform, "cuda") && platform["cuda"] != "none" 

        append!(_dependencies, CUDA.required_dependencies(platform, static_sdk=true))

        cuda_ver = platform["cuda"]

        # Add x86_64 CUDA_SDK, nvcc isn't actually used but CMake
        # FindCUDAToolkit will get mad if its not present
        if arch(platform) == "aarch64"
            push!(platform_sources, CUDA.cuda_nvcc_redist_source(cuda_ver, "x86_64"))
        end

        script = get_script(Val{true}())
    end

    build_tarballs(
        ARGS, name, version, platform_sources, 
        script, [platform], products, _dependencies;
        julia_compat = "1.10", 
        preferred_gcc_version = v"11",
        lazy_artifacts = true,
        augment_platform_block = CUDA.augment
    )

end
