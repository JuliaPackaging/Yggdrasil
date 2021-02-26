using BinaryBuilder

cuda_version = v"10.2.89"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.1.0.77/10.2_20210127/cudnn-10.2-linux-x64-v8.1.0.77.tgz",
                  "c5bc617d89198b0fbe485156446be15a08aee37f7aff41c797b120912f2b14b4")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.1.0.77/10.2_20210127/cudnn-10.2-windows10-x64-v8.1.0.77.zip",
                  "508a7aaad4e9a167b63cc063018541c74e089a1f548715832c50249dc2098dfa")
]

include("../common.jl")
