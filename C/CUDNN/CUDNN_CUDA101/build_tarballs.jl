using BinaryBuilder

cuda_version = v"10.1.243"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.4/10.1_20200923/cudnn-10.1-linux-x64-v8.0.4.30.tgz",
                  "eb4b888e61715168f57a0a0a21c281ada6856b728e5112618ed15f8637487715")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.4/10.1_20200923/cudnn-10.1-linux-ppc64le-v8.0.4.30.tgz",
                  "690811bbf04adef635f4a6f480575fc2a558c4a2c98c85c7090a3a8c60dacea9")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.4/10.1_20200923/cudnn-10.1-windows10-x64-v8.0.4.30.zip",
                  "f9a7e6632ac1e2058676eed141d05ce34d8b479df388cdc80334356dce63bac2")
]

include("../common.jl")
