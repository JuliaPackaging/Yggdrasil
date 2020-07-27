using BinaryBuilder

cuda_version = v"11.0.2"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.1.13/11.0_20200626/cudnn-11.0-linux-x64-v8.0.1.13.tgz",
                  "03cbe5844ff01b3550ba5d0bbf6eab1c33630f18669978af2a7ebf7366a5c442")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.1.13/11.0_20200626/cudnn-11.0-linux-ppc64le-v8.0.1.13.tgz",
                  "2529819229eed31c56562b2791f10cba6ce5c729e1d1816933c8ac2b6535075d")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.1.13/11.0_20200626/cudnn-11.0-windows-x64-v8.0.1.13.zip",
                  "72cbf300a23fa1ef737dc217d93c7cbcf10ed4a3f5d3be2b4261dfab1ba14d8d")
]

include("../common.jl")
