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
cuda_version = v"13.3.0"
driver_version = "610.43.02"

# the JLL version tracks `cuda_version`, but can diverge in the patch digit when the
# wrapper code changes in ways consumers need to express compat bounds against (Julia
# package resolution cannot distinguish build numbers). 13.3.1: introduction of the
# toolkit selection library in the toplevel block. 13.3.2: detailed driver-inspection
# failure diagnostics and the `tegra` platform tag with per-KMD-generation artifacts
# shipping the L4T compatibility drivers.
version = v"13.3.2"

# the Tegra compat drivers to ship, per kernel-mode driver generation (the `tegra`
# platform tag; see tegra_detection.jl). NVIDIA built L4T compat UMDs against the r35
# KMD through CUDA 12.2 and against r36 through 12.9; only the newest UMD per KMD
# generation is worth shipping (any older toolkit runs on a newer same-major UMD).
# no compat driver exists for r32 (JetPack 4), and from r38 (JetPack 7) on the
# driver ships with the L4T BSP itself, so those get helper-only artifacts.
tegra_compat_drivers = [
    # tegra tag => (cuda version of the redist manifest, compat driver version)
    "35" => (v"12.2.2", v"12.2.34086590"),
    "36" => (v"12.9.1", v"12.9.40580548"),
]
tegra_helper_only = ["32", "38"]

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
    # ships this on Linux. Helper-only builds have no cuda_compat source.
    if [[ ${target} == *-linux-gnu ]] && compgen -G "${WORKSPACE}/srcdir/cuda_compat*" >/dev/null; then
        mkdir -p ${libdir}
        cd ${WORKSPACE}/srcdir/cuda_compat*
        install_license LICENSE
        mv compat/* ${libdir}
        # the L4T packages also contain MPS executables; keep those in bindir
        mv ${libdir}/nvidia-cuda-mps-* ${bindir} 2>/dev/null || true
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
# the datacenter/sbsa compat driver, as shipped with the CUDA toolkit
compat_products = [
    LibraryProduct("libcuda", :libcuda_compat;                            dont_dlopen=true),
    LibraryProduct("libcudadebugger", :libcuda_debugger;                  dont_dlopen=true),
    LibraryProduct("libnvidia-gpucomp", :libnvidia_gpucomp;               dont_dlopen=true),
    LibraryProduct("libnvidia-nvvm", :libnvidia_nvvm;                     dont_dlopen=true),
    LibraryProduct("libnvidia-ptxjitcompiler", :libnvidia_ptxjitcompiler; dont_dlopen=true),
    LibraryProduct("libnvidia-tileiras", :libnvidia_tileiras;             dont_dlopen=true),
    helper_product,
]
# the L4T compat drivers lack the newer desktop-only libraries; init.jl only
# references products that are actually defined for the selected artifact
l4t_compat_products = [
    LibraryProduct("libcuda", :libcuda_compat;                            dont_dlopen=true),
    LibraryProduct("libcudadebugger", :libcuda_debugger;                  dont_dlopen=true),
    LibraryProduct("libnvidia-nvvm", :libnvidia_nvvm;                     dont_dlopen=true),
    LibraryProduct("libnvidia-ptxjitcompiler", :libnvidia_ptxjitcompiler; dont_dlopen=true),
    helper_product,
]

dependencies = []

# Every artifact carries an explicit value for the `tegra` tag matching what
# `augment_platform!` computes. This leaves no untagged artifact that could match
# every Tegra generation; in particular, a Tegra host must never receive the
# SBSA/datacenter compat driver, which cannot drive the Tegra iGPU.

builds = []

# platforms that ship the datacenter forwards-compatible driver alongside the helper
for platform in [Platform("x86_64", "linux"; tegra="none"),
                 Platform("aarch64", "linux"; tegra="none")]
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

# Tegra generations with an L4T compat driver
for (tegra, (manifest_version, compat_version)) in tegra_compat_drivers
    platform = Platform("aarch64", "linux"; tegra)
    augmented_platform = deepcopy(platform)
    augmented_platform["cuda"] = CUDA.platform(compat_version)
    should_build_platform(triplet(augmented_platform)) || continue

    # `get_sources` needs the cuda_platform tag to map pre-13 aarch64 onto the
    # Tegra (`linux-aarch64`) entries of the redist manifest
    source_platform = deepcopy(augmented_platform)
    source_platform["cuda_platform"] = "jetson"
    sources = get_sources("cuda", ["cuda_compat"]; version=manifest_version,
                          platform=source_platform)
    push!(sources, DirectorySource("./src"))

    push!(builds, (; platforms=[platform], sources, products=l4t_compat_products))
end

# platforms where we only build the cuda_inspect_driver helper, without a
# forwards-compatible libcuda: Windows (NVIDIA doesn't ship one), and Tegra
# generations without an applicable compat driver. CUDA_Runtime_jll's platform
# augmentation needs the JLL to be `is_available()` on these platforms so it
# can pick a runtime artifact based on the system driver.
helper_only_platforms = [Platform("x86_64", "windows"; tegra="none");
                         [Platform("aarch64", "linux"; tegra) for tegra in tegra_helper_only]]
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

# Private Tegra routing, spliced into the self-contained augmentation block.
# Reusable detection helpers are exposed by the unconditional toplevel block.
tegra_detection = read(joinpath(@__DIR__, "tegra_detection.jl"), String)

# platform augmentation: set the `tegra` tag so that Tegra hosts select the
# artifact with the compat driver matching their kernel-mode driver generation.
# Re-adding this block makes Pkg spawn an artifact-selection subprocess for this
# JLL during package operations (add/instantiate/etc), not during ordinary use.
augment_platform_block = """
    using Base.BinaryPlatforms

    $(tegra_detection)

    function augment_platform!(platform::Platform)
        haskey(platform, "tegra") && return platform
        platform["tegra"] = _tegra_artifact_generation()
        return platform
    end"""

# driver inspection and toolkit selection functionality, shared with the platform
# augmentation hooks of dependent JLLs (which access it with `using CUDA_Driver_jll`)
# and with CUDA.jl. this goes into the module's `toplevel_block` so that it is defined
# unconditionally, even on platforms without a matching artifact.
#
# The augmentation block is also included in the JLL module, so the toplevel block
# can expose the private Tegra detection through public wrappers without repeating its
# definitions (which would cause method-overwrite errors during precompilation). The
# clamped artifact-generation function remains an implementation detail.
toplevel_block = read(joinpath(@__DIR__, "toplevel.jl"), String)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, build.products, dependencies;
                   skip_audit=true, init_block, julia_compat="1.10",
                   augment_platform_block, toplevel_block)
end
