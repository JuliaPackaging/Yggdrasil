using BinaryBuilder, Pkg

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUDA_Compiler"
version = v"0.5.0"

const toolkit_versions = [CUDA.cuda_full_versions; CUDA.cuda_prerelease_versions]
const compiler_versions = filter(v -> v >= v"11.4", toolkit_versions)

augment_platform_block = """
    const CUDA_jll_uuid = Base.UUID("d1e2174e-dfdc-576e-b43e-73b79eb1aca8")
    $(read(joinpath(@__DIR__, "..", "CUDA_Runtime", "toolkit_selection.jl"), String))
    const cuda_toolkits = $(compiler_versions)
    const cuda_prerelease_toolkits = $(CUDA.cuda_prerelease_versions)
    const cuda_default_toolkit = $(repr(Base.thisminor(last(CUDA.cuda_full_versions))))
    $(read(joinpath(@__DIR__, "platform_augmentation.jl"), String))"""

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

    mv cuda_nvrtc/lib/libnvrtc.so* ${libdir}
    mv cuda_nvrtc/lib/libnvrtc-builtins.so* ${libdir}

    if [[ -d libnvjitlink ]]; then
        mv libnvjitlink/lib/libnvJitLink.so* ${libdir}
    fi

    mv cuda_nvdisasm/bin/nvdisasm ${bindir}
    if [[ -d cuda_tileiras ]]; then
        mv cuda_tileiras/bin/tileiras ${bindir}
    fi
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    # normalize the layout of the library components: starting with CUDA 13 there's an
    # additional `x64` subdirectory, and older versions had DLLs in the lib folder.
    for dir in cuda_nvrtc libnvjitlink; do
        [[ -d ${dir} ]] || continue
        find ${dir} -name x64 -type d -execdir sh -c 'mv x64/* .' \;
        mkdir -p ${dir}/bin ${dir}/lib
        mv ${dir}/lib/*.dll ${dir}/bin 2>/dev/null || true
    done

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

    mv cuda_nvrtc/bin/nvrtc64_* ${bindir}
    mv cuda_nvrtc/bin/nvrtc-builtins64_* ${bindir}

    if [[ -d libnvjitlink ]]; then
        mv libnvjitlink/bin/nvJitLink_*.dll ${bindir}
    fi

    mv cuda_nvdisasm/bin/nvdisasm.exe ${bindir}
    if [[ -d cuda_tileiras ]]; then
        mv cuda_tileiras/bin/tileiras.exe ${bindir}
    fi

    # Fix permissions
    chmod +x ${bindir}/*.exe ${bindir}/*.dll
fi
"""

dependencies = [
    Dependency("CUDA_Driver_jll"; compat="13"),
]

function get_platforms(version::VersionNumber)
    platforms = if version >= v"13"
        [Platform("x86_64", "linux"),
         Platform("aarch64", "linux"),
         Platform("x86_64", "windows")]
    else
        [Platform("x86_64", "linux"),
         Platform("aarch64", "linux"; cuda_platform="jetson"),
         Platform("aarch64", "linux"; cuda_platform="sbsa"),
         Platform("x86_64", "windows")]
    end

    filter!(platforms) do platform
        arch(platform) == "aarch64" || return true

        minor = Base.thisminor(version)
        if v"11" <= minor < v"11.8" && platform["cuda_platform"] == "jetson"
            return false
        end
        if minor == v"12.3" && platform["cuda_platform"] == "jetson"
            return false
        end
        return true
    end

    return platforms
end

function get_products(version::VersionNumber)
    # Windows DLL names of the JIT libraries embed (parts of) the toolkit version
    nvrtc_dll = version >= v"13" ? "nvrtc64_130_0" :
                version >= v"12" ? "nvrtc64_120_0" :
                                   "nvrtc64_112_0"
    nvrtc_builtins_dll = "nvrtc-builtins64_$(version.major)$(version.minor)"

    products = [
        FileProduct(["lib/libcudadevrt.a", "lib/cudadevrt.lib"], :libcudadevrt),
        FileProduct("nvvm/libdevice/libdevice.10.bc", :libdevice),
        LibraryProduct(["libnvvm", "nvvm64_40_0"], :libnvvm,
                       ["nvvm/lib64", "nvvm/bin/x64", "nvvm/bin"]),
        LibraryProduct(["libnvrtc", nvrtc_dll], :libnvrtc),
        LibraryProduct(["libnvrtc-builtins", nvrtc_builtins_dll], :libnvrtc_builtins),
        ExecutableProduct("ptxas", :ptxas),
        ExecutableProduct("nvdisasm", :nvdisasm),
        ExecutableProduct("nvlink", :nvlink),
    ]
    if version >= v"12"
        nvjitlink_dll = version >= v"13" ? "nvJitLink_130_0" : "nvJitLink_120_0"
        push!(products, LibraryProduct(["libnvJitLink", nvjitlink_dll], :libnvJitLink))
    end
    if version >= v"13.1"
        push!(products, ExecutableProduct("tileiras", :tileiras))
    end
    return products
end

# determine exactly which tarballs we should build
builds = []
for version in compiler_versions
    # CUDA_Compiler uses the following components
    components = [
        "cuda_cudart",
        "cuda_nvcc",
        "cuda_nvdisasm",
        "cuda_nvrtc",
    ]
    if version >= v"12"
        push!(components, "libnvjitlink")
    end
    if version >= v"13"
        push!(components, "libnvvm")
    end
    if version >= v"13.1"
        push!(components, "cuda_tileiras")
    end

    init_block = "global cuda_version = v\"$(version.major).$(version.minor)\""

    for platform in get_platforms(version)
        augmented_platform = deepcopy(platform)
        augmented_platform["cuda"] = CUDA.platform(version)
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
