# CUDA forward compatibility driver
#
# - https://docs.nvidia.com/deploy/cuda-compatibility/index.html#forward-compatibility-title
# - https://docs.nvidia.com/datacenter/tesla/index.html
# - https://www.nvidia.com/Download/index.aspx

using BinaryBuilder, Pkg

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUDA_Driver"
cuda_version = v"13.2.1"
driver_version = "595.58.03"

script = raw"""
    # Build the driver inspection binary. On Linux/macOS we need -ldl for
    # dlopen/dlsym/dlinfo, and -D_GNU_SOURCE to expose dlinfo/RTLD_DI_LINKMAP;
    # on Windows the equivalent APIs (LoadLibrary etc.) come from kernel32 which
    # is linked implicitly.
    mkdir -p ${bindir}
    if [[ "${target}" == *mingw* ]]; then
        ${CC} -std=c99 -O2 cuda_inspect_driver.c -o ${bindir}/cuda_inspect_driver${exeext}
    else
        ${CC} -std=c99 -O2 -D_GNU_SOURCE cuda_inspect_driver.c -ldl -o ${bindir}/cuda_inspect_driver${exeext}
    fi

    # Install the forwards-compatible driver from the CUDA toolkit. NVIDIA only
    # ships this on Linux.
    if [[ ${target} == *-linux-gnu ]]; then
        mkdir -p ${libdir}
        cd ${WORKSPACE}/srcdir/cuda_compat*
        install_license LICENSE
        mv compat/* ${libdir}
    fi
"""

# CUDA_Driver_jll provides libcuda_compat, but we can't always use that driver: It requires
# specific hardware, and a compatible operating system. So we don't just dlopen the library,
# but instead check during __init__ if we can, and dlopen either the system driver or the
# compatible one from this JLL.
#
# Ordinarily, we'd put this logic in a package that depends on CUDA_Driver_jll (e.g.
# CUDA_Driver.jl), but that complicates depending on it from other JLLs (like
# CUDA_Runtime_jll). This will also simplify moving the logic into CUDA_Runtime_jll, which
# we will have to at some point (because its pkg hooks shouldn't depend on CUDA_Driver_jll).
init_block = read(joinpath(@__DIR__, "init.jl"), String)
init_block = map(eachline(IOBuffer(init_block))) do line
        # indent non-empty lines
        (isempty(line) ? "" : "    ") * line * "\n"
    end |> join

helper_product = ExecutableProduct("cuda_inspect_driver", :cuda_inspect_driver)
compat_products = [
    LibraryProduct("libcuda", :libcuda_compat;                            dont_dlopen=true),
    LibraryProduct("libcudadebugger", :libcuda_debugger;                  dont_dlopen=true),
    LibraryProduct("libnvidia-gpucomp", :libnvidia_gpucomp;               dont_dlopen=true),
    LibraryProduct("libnvidia-nvvm", :libnvidia_nvvm;                     dont_dlopen=true),
    LibraryProduct("libnvidia-ptxjitcompiler", :libnvidia_ptxjitcompiler; dont_dlopen=true),
    LibraryProduct("libnvidia-tileiras", :libnvidia_tileiras;             dont_dlopen=true),
    helper_product,
]

dependencies = []

# Platforms that ship the forwards-compatible driver alongside the helper.
compat_platforms = [Platform("x86_64", "linux"),
                    Platform("aarch64", "linux")]

# Platforms where we only build the cuda_inspect_driver helper, without a
# forwards-compatible libcuda. CUDA_Runtime_jll's platform augmentation needs
# the JLL to be `is_available()` on these platforms so it can pick a runtime
# artifact based on the system driver.
helper_only_platforms = [Platform("x86_64", "windows")]

builds = []
for platform in compat_platforms
    augmented_platform = deepcopy(platform)
    augmented_platform["cuda"] = CUDA.platform(cuda_version)
    should_build_platform(triplet(augmented_platform)) || continue

    # for the cuda compatibility library shipped as part of the CUDA toolkit
    sources = get_sources("cuda", ["cuda_compat"]; version=cuda_version,
                          platform=augmented_platform, variant="cuda$(cuda_version.major).$(cuda_version.minor)")
    # for the datacenter driver
    #sources = get_sources("nvidia-driver", ["cuda_compat"]; version=driver_version,
    #                      platform=augmented_platform, variant="cuda$(cuda_version.major).$(cuda_version.minor)")
    push!(sources, DirectorySource("./src"))

    push!(builds, (; platforms=[platform], sources, products=compat_products))
end
for platform in helper_only_platforms
    augmented_platform = deepcopy(platform)
    augmented_platform["cuda"] = CUDA.platform(cuda_version)
    should_build_platform(triplet(augmented_platform)) || continue

    sources = [DirectorySource("./src")]
    push!(builds, (; platforms=[platform], sources, products=[helper_product]))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

augment_platform_block = """
augment_platform! = identity

$(read(joinpath(@__DIR__, "inspect_driver.jl"), String))
"""

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, cuda_version, build.sources, script,
                   build.platforms, build.products, dependencies;
                   skip_audit=true, init_block, julia_compat="1.10",
                   augment_platform_block)
end
