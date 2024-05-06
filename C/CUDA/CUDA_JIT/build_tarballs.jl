using BinaryBuilder, Pkg

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "CUDA_JIT"
version = v"12.4.1"

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

    mv cuda_nvrtc/lib/libnvrtc.so* ${libdir}
    mv cuda_nvrtc/lib/libnvrtc-builtins.so* ${libdir}

    mv cuda_nvdisasm/bin/nvdisasm ${bindir}

    mv libnvjitlink/lib/libnvJitLink.so* ${libdir}

    # Convert the static compiler library to a dynamic one
    ${CC} -std=c99 -fPIC -shared -lm \
          -L cuda_nvcc/lib -Wl,--whole-archive -lnvptxcompiler_static -Wl,--no-whole-archive \
          -o ${libdir}/libnvPTXCompiler.so
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    mv cuda_cudart/lib/x64/cudadevrt.lib ${prefix}/lib

    mkdir ${prefix}/share/libdevice
    mv cuda_nvcc/bin/ptxas.exe ${bindir}
    mv cuda_nvcc/bin/nvlink.exe ${bindir}
    mv cuda_nvcc/nvvm/libdevice/libdevice.10.bc ${prefix}/share/libdevice

    mv cuda_nvrtc/bin/nvrtc64_* ${bindir}
    mv cuda_nvrtc/bin/nvrtc-builtins64_* ${bindir}

    mv cuda_nvdisasm/bin/nvdisasm.exe ${bindir}

    mv libnvjitlink/bin/nvJitLink_*.dll ${bindir}

    # Convert the static compiler library to a dynamic one
    # XXX: nvptxcompiler_static.lib is a MSVC-generated library, which doesn't work with
    #      our toolchain (__GSHandlerCheck and __security_check_cookie are missing)
    #${CC} -std=c99 -shared -lm \
    #      -L cuda_nvcc/lib -Wl,--whole-archive -lnvptxcompiler_static -Wl,--no-whole-archive \
    #      -o ${libdir}/nvPTXCompiler.dll

    # Fix permissions
    chmod +x ${bindir}/*.{exe,dll}
fi
"""

platforms = [Platform("x86_64", "linux"),
             Platform("powerpc64le", "linux"),
             Platform("aarch64", "linux"),
             Platform("x86_64", "windows")]

function get_products(platform)
    products = [
        LibraryProduct(["libnvJitLink", "nvJitLink_120_0"], :libnvJitLink),
        LibraryProduct(["libnvrtc", "nvrtc64_120_0"], :libnvrtc),
        LibraryProduct(["libnvrtc-builtins", "nvrtc-builtins64_124"], :libnvrtc_builtins),
        FileProduct("share/libdevice/libdevice.10.bc", :libdevice),
        ExecutableProduct("ptxas", :ptxas),
        ExecutableProduct("nvdisasm", :nvdisasm),
        ExecutableProduct("nvlink", :nvlink),
    ]
    if !Sys.iswindows(platform)
        push!(products, LibraryProduct("libnvPTXCompiler", :libnvPTXCompiler))
    end
    return products
end

dependencies = []

builds = []
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    components = [
        "cuda_cudart",
        "cuda_nvcc",
        "cuda_nvrtc",
        "cuda_nvdisasm",
        "libnvjitlink"
    ]
    sources = get_sources("cuda", components; version, platform)
    products = get_products(platform)
    push!(builds, (; platforms=[platform], sources, products))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, build.products, dependencies;
                   julia_compat="1.6", preferred_gcc_version = v"6.1.0")
end
