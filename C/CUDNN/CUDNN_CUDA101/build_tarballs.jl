using BinaryBuilder

cuda_version = v"10.1.243"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.3.33/10.1_20200825/cudnn-10.1-linux-x64-v8.0.3.33.tgz",
                  "4752ac6aea4e4d2226061610d6843da6338ef75a93518aa9ce50d0f58df5fb07")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.3.33/10.1_20200825/cudnn-10.1-linux-ppc64le-v8.0.3.33.tgz",
                  "c546175f6ec86a11ee8fb9ab5526fa8d854322545769a87d35b1a505992f89c3")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.3.33/10.1_20200825/cudnn-10.1-windows10-x64-v8.0.3.33.zip",
                  "9749e8a8f1dc0cfbb8a70d91825d0c5864426b44c3371ada1e077d8bd86b129f")
]

include("../common.jl")
