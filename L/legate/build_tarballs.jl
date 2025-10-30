using BinaryBuilder
import Pkg: PackageSpec
using Base.BinaryPlatforms: arch, os, tags

# Heavily Copies from: https://github.com/JuliaPackaging/Yggdrasil/blob/master/S/SuiteSparse/SuiteSparse_GPU%407/build_tarballs.jl

const YGGDRASIL_DIR = "../../"
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

include("make_script.jl")

name = "legate"
version = v"25.8" # Year.Month
sources = [
    GitSource("https://github.com/nv-legate/legate.git","47132dace5c2bb6cd16ba605eeaa37aea67c564b"),
    DirectorySource("./bundled"),
    FileSource("https://repo.anaconda.com/miniconda/Miniconda3-py311_24.3.0-0-Linux-x86_64.sh", 
                "4da8dde69eca0d9bc31420349a204851bfa2a1c87aeb87fe0c05517797edaac4", "miniconda.sh")
]

MIN_CUDA_VERSION = v"12.2"
MAX_CUDA_VERSION = v"12.8.999" #12.9?

# Just so I can do CPU only tests on GitHub runners
cpu_platform = [Platform("x86_64", "linux")]

cuda_platforms = CUDA.supported_platforms(; min_version = MIN_CUDA_VERSION, max_version = MAX_CUDA_VERSION)
all_platforms = [cpu_platform; cuda_platforms]

filter!(p -> arch(p) == "x86_64" || arch(p) == "aarch64", all_platforms)

all_platforms = expand_cxxstring_abis(all_platforms)
filter!(p -> cxxstring_abi(p) == "cxx11", all_platforms)

# platforms, mpi_dependencies = MPI.augment_platforms(platforms)
# filter!(p -> p["mpi"] ∉ ["mpitrampoline", "microsoftmpi"], platforms)

# manually mark platforms that could support CUDA, set 
# flag so we know that we do NOT want to install CUDA on this one
for platform in all_platforms
    if CUDA.is_supported(platform) && !haskey(platform, "cuda")
        platform["cuda"] = "none"
    end
end


products = [
    LibraryProduct("liblegate", :liblegate)
] 


# Dependencies that do not need CUDA
dependencies = [
    Dependency("HDF5_jll"; compat="~1.14.6"),
    Dependency("MPICH_jll"; compat="4.3.0"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = v"3.31.9")),
]

for platform in all_platforms

    should_build_platform(triplet(platform)) || continue

    platform_sources = BinaryBuilder.AbstractSource[sources...]
    clang_ver = v"17"

    _dependencies = copy(dependencies)
    script = get_script(Val{false}())

    if haskey(platform, "cuda") && platform["cuda"] != "none" 

        cuda_ver = platform["cuda"]
        clang_ver = VersionNumber(cuda_ver) >= v"12.6" ? v"17" : v"13"

        # Add x86_64 CUDA_SDK to cross compile for aarch64
        if arch(platform) == "aarch64"
            push!(platform_sources, CUDA.cuda_nvcc_redist_source(cuda_ver, "x86_64"))
        end

        push!(_dependencies, Dependency("NCCL_jll"; compat="2.26.5"))
        append!(_dependencies, CUDA.required_dependencies(platform, static_sdk=true))

        script = get_script(Val{true}())
    end # else CPU only build

    build_tarballs(ARGS, name, version, platform_sources, script, [platform],
                    products, _dependencies;
                    julia_compat = "1.10", preferred_gcc_version = v"11",
                    preferred_llvm_version = clang_ver,
                    augment_platform_block=CUDA.augment,
                    lazy_artifacts = true, dont_dlopen = true
                )
end
