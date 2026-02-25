using BinaryBuilder, Pkg

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "CUDA_Compiler"
version = v"0.4.1"

augment_platform_block = read(joinpath(@__DIR__, "platform_augmentation.jl"), String)

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
    if [[ -d cuda_nvcc/nvvm ]]; then
        mv cuda_nvcc/nvvm ${prefix}
    else
        mv libnvvm/nvvm ${prefix}
    fi

    mv cuda_nvdisasm/bin/nvdisasm ${bindir}
    if [[ -d cuda_tileiras ]]; then
        mv cuda_tileiras/bin/tileiras ${bindir}
    fi
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    if [[ -d cuda_cudart/lib/x64 ]]; then
        mv cuda_cudart/lib/x64/cudadevrt.lib ${prefix}/lib
    else
        mv cuda_cudart/lib/cudadevrt.lib ${prefix}/lib
    fi

    mkdir ${prefix}/share/libdevice
    mv cuda_nvcc/bin/ptxas.exe ${bindir}
    mv cuda_nvcc/bin/nvlink.exe ${bindir}
    if [[ -d cuda_nvcc/nvvm ]]; then
        mv cuda_nvcc/nvvm ${prefix}
    else
        mv libnvvm/nvvm ${prefix}
    fi

    mv cuda_nvdisasm/bin/nvdisasm.exe ${bindir}
    if [[ -d cuda_tileiras ]]; then
        mv cuda_tileiras/bin/tileiras.exe ${bindir}
    fi

    # Fix permissions
    chmod +x ${bindir}/*.exe
fi
"""

dependencies = [
    Dependency("CUDA_Driver_jll"; compat="13"),
    RuntimeDependency("CUDA_Runtime_jll", top_level=true), # top_level so that preference changes invalidate
]

function get_platforms(version::VersionNumber)
    if version >= v"13"
        [Platform("x86_64", "linux"),
         Platform("aarch64", "linux"),
         Platform("x86_64", "windows")]
    else
        [Platform("x86_64", "linux"),
         Platform("aarch64", "linux"; cuda_platform="jetson"),
         Platform("aarch64", "linux"; cuda_platform="sbsa"),
         Platform("x86_64", "windows")]
    end
end

function get_products(version::VersionNumber)
    products = [
        FileProduct(["lib/libcudadevrt.a", "lib/cudadevrt.lib"], :libcudadevrt),
        FileProduct("nvvm/libdevice/libdevice.10.bc", :libdevice),
        LibraryProduct(["libnvvm", "nvvm64_40_0"], :libnvvm,
                       ["nvvm/lib64", "nvvm/bin/x64", "nvvm/bin"]),
        ExecutableProduct("ptxas", :ptxas),
        ExecutableProduct("nvdisasm", :nvdisasm),
        ExecutableProduct("nvlink", :nvlink),
    ]
    if version >= v"13.1"
        push!(products, ExecutableProduct("tileiras", :tileiras))
    end
    return products
end

# determine exactly which tarballs we should build
builds = []
for version in [ v"11.8", v"12.9", v"13.1"]
    # CUDA_Compiler uses the following components
    components = [
        "cuda_cudart",
        "cuda_nvcc",
        "cuda_nvdisasm"
    ]
    if version >= v"13"
        push!(components, "cuda_tileiras")
        push!(components, "libnvvm")
    end

    init_block = "global cuda_version = v\"$(version.major).$(version.minor)\""

    for platform in get_platforms(version)
        augmented_platform = deepcopy(platform)
        augmented_platform["cuda"] = "$(version.major)"
        should_build_platform(triplet(augmented_platform)) || continue

        push!(builds,
            (; script, platforms=[augmented_platform], products=get_products(version), init_block,
               sources=get_sources("cuda", components; version, platform=augmented_platform),
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

# bump
