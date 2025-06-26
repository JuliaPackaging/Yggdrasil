using BinaryBuilder, Pkg

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "CUDA_Compiler"
version = v"0.1"

augment_platform_block = read(joinpath(@__DIR__, "platform_augmentation.jl"), String)

platforms = [Platform("x86_64", "linux"),
             Platform("aarch64", "linux"; cuda_platform="jetson"),
             Platform("aarch64", "linux"; cuda_platform="sbsa"),
             Platform("x86_64", "windows")]

script = raw"""
# rename directories, stripping the architecture and version suffix
for dir in *-archive; do
    base=$(echo $dir | cut -d '-' -f 1)
    mv $dir $base
done

# license
install_license cuda_nvcc/LICENSE

# binaries
mkdir -p ${bindir} ${libdir} ${prefix}/lib ${prefix}/share
if [[ ${target} == *-linux-gnu ]]; then
    mv cuda_cudart/lib/libcudadevrt.a ${libdir}

    mkdir ${prefix}/share/libdevice
    mv cuda_nvcc/bin/ptxas ${bindir}
    mv cuda_nvcc/bin/nvlink ${bindir}
    mv cuda_nvcc/nvvm/libdevice/libdevice.10.bc ${prefix}/share/libdevice

    mv cuda_nvdisasm/bin/nvdisasm ${bindir}
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    if [[ -d cuda_cudart/lib/x64 ]]; then
        mv cuda_cudart/lib/x64/cudadevrt.lib ${prefix}/lib
    else
        mv cuda_cudart/lib/cudadevrt.lib ${prefix}/lib
    fi

    mkdir ${prefix}/share/libdevice
    mv cuda_nvcc/bin/ptxas.exe ${bindir}
    mv cuda_nvcc/bin/nvlink.exe ${bindir}
    mv cuda_nvcc/nvvm/libdevice/libdevice.10.bc ${prefix}/share/libdevice

    mv cuda_nvdisasm/bin/nvdisasm.exe ${bindir}

    # Fix permissions
    chmod +x ${bindir}/*.exe
fi
"""

dependencies = [
    Dependency("CUDA_Driver_jll", v"12.9"; compat="12")
]

# determine exactly which tarballs we should build
builds = []
for version in [ v"11.8", v"12.9"]
    include("build_$(version.major).jl")

    # CUDA_Compiler uses the following components
    components = [
        "cuda_cudart",
        "cuda_nvcc",
        "cuda_nvdisasm"
    ]

    init_block = "global cuda_version = v\"$(version.major).$(version.minor)\""

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform["cuda"] = "$(version.major)"
        should_build_platform(triplet(augmented_platform)) || continue

        push!(builds,
            (; script, platforms=[augmented_platform], products, init_block,
               sources=get_sources("cuda", components; version, platform),
        ))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` and `--deploy` should only be passed to the final `build_tarballs` invocation
non_reg_ARGS = filter(non_platform_ARGS) do arg
    arg != "--register" && !startswith(arg, "--deploy")
end

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, build.script,
                   build.platforms, build.products, dependencies;
                   julia_compat="1.6", lazy_artifacts=true,
                   augment_platform_block, build.init_block)
end
