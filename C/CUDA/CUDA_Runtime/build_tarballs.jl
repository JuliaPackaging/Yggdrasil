using BinaryBuilder, Pkg

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUDA_Runtime"
version = v"0.15.5"

augment_platform_block = """
    $(read(joinpath(@__DIR__, "platform_augmentation.jl"), String))
    const cuda_toolkits = $(CUDA.cuda_full_versions)"""

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
install_license cuda_cudart/LICENSE

# binaries
mkdir -p ${bindir} ${libdir} ${prefix}/lib ${prefix}/share
if [[ ${target} == *-linux-gnu ]]; then
    mv cuda_cudart/lib/libcudart.so* cuda_cudart/lib/libcudadevrt.a ${libdir}

    mv cuda_cupti/lib/libcupti.so* ${libdir}
    mv cuda_cupti/lib/libnvperf_host.so* ${libdir}
    mv cuda_cupti/lib/libnvperf_target.so* ${libdir}

    mkdir ${prefix}/share/libdevice
    mv cuda_nvcc/nvvm/lib64/libnvvm.so* ${libdir}
    mv cuda_nvcc/bin/ptxas ${bindir}
    mv cuda_nvcc/bin/nvlink ${bindir}
    mv cuda_nvcc/nvvm/libdevice/libdevice.10.bc ${prefix}/share/libdevice

    mv cuda_nvrtc/lib/libnvrtc.so* ${libdir}
    mv cuda_nvrtc/lib/libnvrtc-builtins.so* ${libdir}

    mv cuda_nvdisasm/bin/nvdisasm ${bindir}

    if [[ -d libnvjitlink ]]; then
        mv libnvjitlink/lib/libnvJitLink.so* ${libdir}
    fi

    mv libcufft/lib/libcufft.so* libcufft/lib/libcufftw.so* ${libdir}

    mv libcublas/lib/libcublas.so* libcublas/lib/libcublasLt.so* ${libdir}

    mv libcusparse/lib/libcusparse.so* ${libdir}

    mv libcusolver/lib/libcusolver.so* libcusolver/lib/libcusolverMg.so* ${libdir}

    mv libcurand/lib/libcurand.so* ${libdir}
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    # older versions of the redist binaries had DLLs in the lib folder; correct that
    for dir in */; do
        mkdir -p $dir/bin $dir/lib
        mv $dir/lib/*.dll $dir/bin || true
    done

    mv cuda_cudart/bin/cudart64_*.dll ${bindir}
    if [[ -d cuda_cudart/lib/x64 ]]; then
        mv cuda_cudart/lib/x64/cudadevrt.lib ${prefix}/lib
    else
        mv cuda_cudart/lib/cudadevrt.lib ${prefix}/lib
    fi

    mv cuda_cupti/bin/cupti64_*.dll ${bindir}
    mv cuda_cupti/bin/nvperf_host.dll* ${libdir}
    mv cuda_cupti/bin/nvperf_target.dll* ${libdir}

    mkdir ${prefix}/share/libdevice
    mv cuda_nvcc/nvvm/bin/nvvm64_*.dll ${bindir}
    mv cuda_nvcc/bin/ptxas.exe ${bindir}
    mv cuda_nvcc/bin/nvlink.exe ${bindir}
    mv cuda_nvcc/nvvm/libdevice/libdevice.10.bc ${prefix}/share/libdevice

    mv cuda_nvrtc/bin/nvrtc64_* ${bindir}
    mv cuda_nvrtc/bin/nvrtc-builtins64_* ${bindir}

    mv cuda_nvdisasm/bin/nvdisasm.exe ${bindir}

    if [[ -d libnvjitlink ]]; then
        mv libnvjitlink/bin/nvJitLink_*.dll ${bindir}
    fi

    mv libcufft/bin/cufft64_*.dll libcufft/bin/cufftw64_*.dll ${bindir}

    mv libcublas/bin/cublas64_*.dll libcublas/bin/cublasLt64_*.dll ${bindir}

    mv libcusparse/bin/cusparse64_*.dll ${bindir}

    mv libcusolver/bin/cusolver64_*.dll libcusolver/bin/cusolverMg64_*.dll ${bindir}

    mv libcurand/bin/curand64_*.dll ${bindir}

    # Fix permissions
    chmod +x ${bindir}/*.{exe,dll}
fi
"""

# determine exactly which tarballs we should build
builds = []
for version in CUDA.cuda_full_versions
    include("build_$(version.major).$(version.minor).jl")

    # CUDA_Runtime contains all of the following components
    # XXX: consider splitting these into separate packages once BinaryBuilder supports it
    components = [
        "cuda_cudart",
        "cuda_cupti",
        "cuda_nvcc",
        "cuda_nvrtc",
        "cuda_nvdisasm",

        "libcublas",
        "libcufft",
        "libcurand",
        "libcusolver",
        "libcusparse",
    ]
    if version >= v"12"
        push!(components, "libnvjitlink")
    end

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform["cuda"] = CUDA.platform(version)

        should_build_platform(triplet(augmented_platform)) || continue

        if arch(platform) == "aarch64"
            # CUDA 10.x: our CUDA 10.2 build recipe for arm64 only provides jetson binaries
            if thisminor(version) == v"10.2" && platform["cuda_platform"] != "jetson"
                continue
            end

            # CUDA 11.x: only 11.8 has jetson binaries on the redist server
            if v"11.0" <= thisminor(version) < v"11.8" && platform["cuda_platform"] == "jetson"
                continue
            end

            # CUDA 12.x: the jetson binaries for 12.3 seem to be missing
            if thisminor(version) == v"12.3" && platform["cuda_platform"] == "jetson"
                continue
            end
        end

        if Base.thisminor(version) == v"10.2"
            push!(builds,
                (; dependencies=[Dependency("CUDA_Driver_jll"; compat="0.10"),
                                 BuildDependency(PackageSpec(name="CUDA_SDK_jll", version=v"10.2.89"))],
                   script=get_script(), platforms=[augmented_platform], products=get_products(platform),
                   sources=[]
            ))
        else
            push!(builds,
                (; dependencies=[Dependency("CUDA_Driver_jll"; compat="0.10")],
                   script, platforms=[augmented_platform], products=get_products(platform),
                   sources=get_sources("cuda", components; version, platform)
            ))
        end
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, build.script,
                   build.platforms, build.products, build.dependencies;
                   julia_compat="1.6", lazy_artifacts=true, augment_platform_block)
end
