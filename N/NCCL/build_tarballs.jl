# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "NCCL"
version = v"2.28.3"

script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir
cd nccl*
find .

install_license LICENSE.txt

mv lib/libnccl*.so* ${libdir}
mv include/* ${prefix}/include
"""

products = [
    LibraryProduct("libnccl", :libnccl),
]

dependencies = [
    HostBuildDependency("coreutils_jll"), # requires fmt
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

builds = []
for cuda_version in [v"12.9", v"13.0"]
    platforms = [
        Platform("x86_64", "linux"),
        Platform("aarch64", "linux")
    ]

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform["cuda"] = CUDA.platform(cuda_version)
        should_build_platform(triplet(augmented_platform)) || continue

        if cuda_version == v"12.9"
            if arch(platform) == "aarch64"
                hash = "c51b970bb26a0d3afd676048923fc404ed1d1131441558a7d346940e93d6ab54"
            elseif arch(platform) == "x86_64"
                hash = "98f7abd2f505ba49f032052f3f36b14e28798a6e16ca783fe293e351e9376546"
            end
        else
            if arch(platform) == "aarch64"
                hash = "2b5961c4c4bcbc16148d8431c7b65525d00f386105ab1b9fa82051b7c05f6fd0"
            elseif arch(platform) == "x86_64"
                hash = "3117db0efe13e1336dbe32e8b98eab943ad5baa69518189918d4aca9e3ce3270"
            end
        end

        sources = [
            ArchiveSource("https://developer.download.nvidia.com/compute/redist/nccl/v$(version)/nccl_$(version)-1+cuda$(cuda_version.major).$(cuda_version.minor)_$(arch(platform)).txz", hash)
        ]

        push!(builds, (; platforms=[augmented_platform], sources))
    end
end


# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
        name, version, build.sources, script,
        build.platforms, products, dependencies;
        julia_compat="1.10", augment_platform_block=CUDA.augment,
        preferred_gcc_version=v"10")
end
