# CUDA forward compatibility driver
#
# - https://docs.nvidia.com/deploy/cuda-compatibility/index.html#forward-compatibility-title
# - https://docs.nvidia.com/datacenter/tesla/index.html
# - https://www.nvidia.com/Download/index.aspx

using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "CUDA_Driver"
version = v"13.1.0"

version_str = "$(version.major)-$(version.minor)"
driver_str = "590.44.01"
build = 1

sources_linux_x86 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-compat-$(version_str)-$(driver_str)-$(build).el8.x86_64.rpm",
               "a1c9f934c6c5b4a566c907f9cc55e8505b17b00b35163fdb5342c4811cd33798", "compat.rpm")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/sbsa/cuda-compat-$(version_str)-$(driver_str)-$(build).el8.aarch64.rpm",
               "e7233912d7a2f4529673a70702f3dd5a1350228db51e31c0f160468fde2663bf", "compat.rpm")
]

dependencies = []

script = raw"""
    apk update
    apk add rpm2cpio
    rpm2cpio compat.rpm | cpio -idmv

    mkdir -p ${libdir}

    mv usr/local/cuda-*/compat/* ${libdir}
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
    LibraryProduct("libnvidia-nvvm", :libnvidia_nvvm;                     dont_dlopen=true),
    LibraryProduct("libnvidia-ptxjitcompiler", :libnvidia_ptxjitcompiler; dont_dlopen=true),
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

if should_build_platform("x86_64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_x86, script,
                   [Platform("x86_64", "linux")], products, dependencies;
                   skip_audit=true, init_block)
end

if should_build_platform("aarch64-linux-gnu")
    build_tarballs(ARGS, name, version, sources_linux_aarch64, script,
                   [Platform("aarch64", "linux")], products, dependencies;
                   skip_audit=true, init_block)
end
