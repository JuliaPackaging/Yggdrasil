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
cuda_version = v"13.1"
driver_version = "590.48.01"

script = raw"""
    # Build the driver inspection binary
    mkdir -p ${bindir}
    ${CC} -std=c99 -ldl cuda_inspect_driver.c -o ${bindir}/cuda_inspect_driver

    mkdir -p ${libdir}

    cd ${WORKSPACE}/srcdir/cuda_compat*

    install_license LICENSE

    mv compat/* ${libdir}
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

products = [
    LibraryProduct("libcuda", :libcuda_compat;                            dont_dlopen=true),
    LibraryProduct("libcudadebugger", :libcuda_debugger;                  dont_dlopen=true),
    LibraryProduct("libnvidia-gpucomp", :libnvidia_gpucomp;               dont_dlopen=true),
    LibraryProduct("libnvidia-nvvm", :libnvidia_nvvm;                     dont_dlopen=true),
    LibraryProduct("libnvidia-ptxjitcompiler", :libnvidia_ptxjitcompiler; dont_dlopen=true),
    LibraryProduct("libnvidia-tileiras", :libnvidia_tileiras;             dont_dlopen=true),
    ExecutableProduct("cuda_inspect_driver", :cuda_inspect_driver)
]

dependencies = []

platforms = [Platform("x86_64", "linux"),
             Platform("aarch64", "linux")]

builds = []
for platform in platforms
    augmented_platform = deepcopy(platform)
    augmented_platform["cuda"] = CUDA.platform(cuda_version)
    should_build_platform(triplet(augmented_platform)) || continue

    sources = get_sources("nvidia-driver", ["cuda_compat"]; version=driver_version,
                          platform=augmented_platform, variant="cuda$(cuda_version.major).$(cuda_version.minor)")
    push!(sources, DirectorySource("./src"))

    push!(builds, (; platforms=[platform], sources))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, cuda_version, build.sources, script,
                   build.platforms, products, dependencies;
                   skip_audit=true, init_block, julia_compat="1.10",
                   augment_platform_block="""
                   # This shaves ~120ms off the load time
                   precompile(Base.cmd_gen, (Tuple{Tuple{Base.Cmd}, Tuple{String}, Tuple{Bool}, Tuple{Array{String, 1}}},))
                   precompile(Base.read, (Base.Cmd, Type{String}))
                   precompile(Tuple{typeof(Base.arg_gen), Bool})

                   augment_platform! = identity
                   """)
end
