using BinaryBuilder

cuda_version = v"10.2.89"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.3.33/10.2_20200825/cudnn-10.2-linux-x64-v8.0.3.33.tgz",
                  "b3d487c621e24b5711983b89bb8ad34f0378bdbf8a1a4b86eefaa23b19956dcc")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.3.33/10.2_20200825/cudnn-10.2-linux-ppc64le-v8.0.3.33.tgz",
                  "ff22c9c37af191c9104989d784427cde744cdde879bfebf3e4e55ca6a9634a11")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.3.33/10.2_20200825/cudnn-10.2-windows10-x64-v8.0.3.33.zip",
                  "45ffcb6ef3a493995d442a8503186f54c5147a1a3c94fdf9e40846a2ce53b64b")
]

include("../common.jl")
