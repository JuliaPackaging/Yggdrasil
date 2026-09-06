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
# package resolution cannot distinguish build numbers). 13.3.1: introduction of a
# toolkit selection library in the toplevel block. 13.3.2: detailed driver-inspection
# failure diagnostics and the `tegra` platform tag with per-KMD-generation artifacts
# shipping the L4T compatibility drivers. 13.3.3: report the driver we actually load,
# rather than always the system one, when selecting a CUDA toolkit. 13.3.4: driver
# decision only; toolkit selection moved to CUDA_Runtime_jll/CUDA_Compiler_jll, so the
# selection library is gone and `libcuda` is defined on every platform (the helper-only
# artifacts for Windows and non-L4T Tegra generations, which only existed to serve that
# library, are gone too).
version = v"13.3.4"

# the Tegra compat drivers to ship, per kernel-mode driver generation (the `tegra`
# platform tag; see tegra_detection.jl). NVIDIA built L4T compat UMDs against the r35
# KMD through CUDA 12.2 and against r36 through 12.9; only the newest UMD per KMD
# generation is worth shipping (any older toolkit runs on a newer same-major UMD).
# no compat driver exists for r32 (JetPack 4), and from r38 (JetPack 7) on the
# driver ships with the L4T BSP itself, so those generations get no artifact at all
# and run on their system driver.
tegra_compat_drivers = [
    # tegra tag => (cuda version of the redist manifest, compat driver version)
    "35" => (v"12.2.2", v"12.2.34086590"),
    "36" => (v"12.9.1", v"12.9.40580548"),
]

script = raw"""
    # Build the driver inspection binary. We need -ldl for dlopen/dlsym/dlinfo, and
    # -D_GNU_SOURCE to expose dlinfo/RTLD_DI_LINKMAP.
    mkdir -p ${bindir}
    ${CC} -std=c99 -O2 -D_GNU_SOURCE cuda_inspect_driver.c -ldl -o ${bindir}/cuda_inspect_driver${exeext}

    # Install the forwards-compatible driver from the CUDA toolkit.
    mkdir -p ${libdir}
    cd ${WORKSPACE}/srcdir/cuda_compat*
    install_license LICENSE
    mv compat/* ${libdir}
    # the L4T packages also contain MPS executables; keep those in bindir
    mv ${libdir}/nvidia-cuda-mps-* ${bindir} 2>/dev/null || true
"""

# CUDA_Driver_jll provides libcuda_compat, but we can't always use that driver: It requires
# specific hardware, and a compatible operating system. So we don't just dlopen the library,
# but instead check during __init__ if we can, and dlopen either the system driver or the
# compatible one from this JLL. The outcome is `libcuda`, the only thing dependents (the
# platform augmentation hooks of CUDA_Runtime_jll/CUDA_Compiler_jll, and CUDA.jl) need
# from this package: they query that driver themselves to select a toolkit.
#
# Ordinarily, we'd put this logic in a package that depends on CUDA_Driver_jll (e.g.
# CUDA_Driver.jl), but that complicates depending on it from other JLLs (like
# CUDA_Runtime_jll).
init_block = read(joinpath(@__DIR__, "init.jl"), String)
init_block = map(eachline(IOBuffer(init_block))) do line
        # indent non-empty lines
        (isempty(line) ? "" : "    ") * line * "\n"
    end |> join

# `__init__` compares the bundled driver against the system one without loading either
# into the current process; this helper does the out-of-process inspection.
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
# SBSA/datacenter compat driver, which cannot drive the Tegra iGPU. Platforms
# without a compat driver (Windows, Tegra generations other than r35/r36) get no
# artifact: the JLL is then `!is_available()` and `libcuda` names the system driver.

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

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

# platform augmentation: set the `tegra` tag so that Tegra hosts select the
# artifact with the compat driver matching their kernel-mode driver generation.
# This block makes Pkg spawn an artifact-selection subprocess for this JLL during
# package operations (add/instantiate/etc), not during ordinary use. It runs in
# that standalone subprocess, where the JLL cannot import itself, so the detection
# code is self-contained (and private: the block is also included in the JLL
# module, but nothing else is meant to call it).
augment_platform_block = raw"""
    using Base.BinaryPlatforms

    function _is_tegra()
        if isfile("/etc/nv_tegra_release")
            return true
        end
        if isfile("/proc/device-tree/compatible") &&
            contains(read("/proc/device-tree/compatible", String), "tegra")
            return true
        end
        return false
    end

    # the NVIDIA Linux for Tegra release, e.g. v"35.6.5", or `nothing`
    function _l4t_version()
        try
            isfile("/etc/nv_tegra_release") || return nothing
            release = read("/etc/nv_tegra_release", String)
            m = match(r"^# R(\d+) \(release\), REVISION: ([0-9]+(?:\.[0-9]+)*)", release)
            m === nothing && return nothing
            return tryparse(VersionNumber, string(m.captures[1], ".", m.captures[2]))
        catch
            return nothing
        end
    end

    # The value of the `tegra` platform tag for the current host: "none" on non-Tegra
    # systems, or the L4T major version (the kernel-mode driver generation, e.g. "35"
    # for JetPack 5) bucketed into the generations we distinguish: "32" (JetPack 4 and
    # earlier: no compat driver exists), "35" (JetPack 5: compat drivers up to CUDA
    # 12.2), "36" (JetPack 6: up to CUDA 12.9), and "38" (JetPack 7 and later, and
    # unidentifiable L4T versions: no compat driver applies). Only "35" and "36" have
    # an artifact; the others match nothing, which is the point: a Tegra host must
    # never receive the SBSA compat driver. This function never throws.
    function _tegra_artifact_generation()
        tegra = try
            _is_tegra()
        catch
            false
        end
        tegra || return "none"

        try
            l4t = _l4t_version()
            l4t === nothing && return "38"
            if l4t.major < 35
                return "32"
            elseif l4t.major == 35
                return "35"
            elseif 36 <= l4t.major < 38
                return "36"
            else
                return "38"
            end
        catch
            return "38"
        end
    end

    function augment_platform!(platform::Platform)
        haskey(platform, "tegra") && return platform
        platform["tegra"] = _tegra_artifact_generation()
        return platform
    end"""

# `libcuda` and the compat preference recording, defined unconditionally (even on
# platforms without a matching artifact) so that dependents can always rely on them.
toplevel_block = read(joinpath(@__DIR__, "toplevel.jl"), String)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, build.products, dependencies;
                   skip_audit=true, init_block, julia_compat="1.10",
                   augment_platform_block, toplevel_block)
end
