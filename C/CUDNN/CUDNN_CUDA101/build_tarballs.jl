using BinaryBuilder

cuda_version = v"10.1.243"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.2.39/10.1_20200626/cudnn-10.1-linux-x64-v8.0.2.39.tgz",
                  "82148a68bd6bdaab93af5e05bb1842b8ccb3ab7de7bed41f609a7616c102213d")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.2.39/10.1_20200626/cudnn-10.1-linux-ppc64le-v8.0.2.39.tgz",
                  "8196ec4f031356317baeccefbc4f61c8fccb2cf0bdef0a6431438918ddf68fb9")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.2.39/10.1_20200626/cudnn-10.1-windows10-x64-v8.0.2.39.zip",
                  "4922e878681502c7135e1b9c7702d6d9b05b5c0d5a175bb91d878bf076657948")
]

include("../common.jl")
