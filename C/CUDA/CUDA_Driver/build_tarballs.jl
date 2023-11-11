# CUDA forward compatibility driver
#
# - https://docs.nvidia.com/deploy/cuda-compatibility/index.html#forward-compatibility-title
# - https://docs.nvidia.com/datacenter/tesla/index.html
# - https://www.nvidia.com/Download/index.aspx

using BinaryBuilder, Pkg

include("../../../fancy_toys.jl")

name = "CUDA_Driver"
version = v"0.7"

cuda_version = v"12.3"
cuda_version_str = "$(cuda_version.major)-$(cuda_version.minor)"
driver_version_str = "545.23.06"
build = 1

sources_linux_x86 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-compat-$(cuda_version_str)-$(driver_version_str)-$(build).x86_64.rpm",
               "04167d1f1fd1eab887c7ea512f779a0de5c32f6c6b66ab2e840c7548621aa1d9", "compat.rpm")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/ppc64le/cuda-compat-$(cuda_version_str)-$(driver_version_str)-$(build).ppc64le.rpm",
               "cd8f0bb34757063b2c5eb0fc901a6bf0740a173ac2048d71c8ba4dda05818aef", "compat.rpm")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/sbsa/cuda-compat-$(cuda_version_str)-$(driver_version_str)-$(build).aarch64.rpm",
               "b0d2fffbbd30e048844c5b4cef495c85f5abd210084d896bf93f2193cf1f060a", "compat.rpm")
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
init_block = "\nglobal compat_version = $(repr(cuda_version))\n" *
             read(joinpath(@__DIR__, "init.jl"), String)
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
                   lazy_artifacts=true, skip_audit=true, init_block)
end

if should_build_platform("powerpc64le-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_ppc64le, script,
                   [Platform("powerpc64le", "linux")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true, init_block)
end

if should_build_platform("aarch64-linux-gnu")
    build_tarballs(ARGS, name, version, sources_linux_aarch64, script,
                   [Platform("aarch64", "linux")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true, init_block)
end
