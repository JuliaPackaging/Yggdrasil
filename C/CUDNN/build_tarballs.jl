using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUDNN"
version = v"8.3.2"

script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir/cudnn*

install_license LICENSE

if [[ ${target} == powerpc64le-linux-gnu ]]; then
    mv lib/libcudnn*.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == *-linux-gnu ]]; then
    mv lib/libcudnn*.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    mv bin/cudnn*64_*.dll ${libdir}
    mv include/* ${prefix}/include

    mv ../dll_x64/zlibwapi.dll ${libdir}

    # fixup
    chmod +x ${libdir}/*.dll
fi
"""

augment_platform_block = """
    using Base.BinaryPlatforms

    using CUDA_Runtime_jll
    $(CUDA.augment)

    function augment_platform!(platform::Platform)
        augment_cuda_dependent!(platform)
    end"""

products = [
    LibraryProduct(["libcudnn", "cudnn64_$(version.major)"], :libcudnn),
]

# determine exactly which tarballs we should build
builds = []
cuda_versions = [v"10.2", v"11.5"]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    include("build_$(cuda_tag).jl")

    for (platform, sources) in platforms_and_sources
        augmented_platform = deepcopy(platform)
        augmented_platform[CUDA.platform_name] = CUDA.platform(cuda_version)
        should_build_platform(triplet(augmented_platform)) || continue

        if platform == Platform("x86_64", "windows")
            push!(sources,
                ArchiveSource("http://www.winimage.com/zLibDll/zlib123dllx64.zip",
                              "fd324c6923aa4f45a60413665e0b68bb34a7779d0861849e02d2711ff8efb9a4"))
        end

        dependencies = [Dependency(PackageSpec(name="CUDA_Runtime_jll", uuid="76a88914-d11a-5bdc-97e0-2f5a05c973a2");
                                   platforms=[augmented_platform])]

        push!(builds, (;
            sources, dependencies, platforms=[augmented_platform],
        ))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, products, build.dependencies;
                   julia_compat="1.6", lazy_artifacts=true,
                   augment_platform_block)
end

