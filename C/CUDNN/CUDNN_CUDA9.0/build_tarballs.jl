using BinaryBuilder

cuda_version = v"9.0.176"   # NOTE: could be less specific

sources_linux = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/9.0_20191031/cudnn-9.0-linux-x64-v7.6.5.32.tgz",
                  "bd0a4c0090d5b02feec3f195738968690cc2470b9bc6026e6fe8ff245cd261c8")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/9.0_20191031/cudnn-9.0-windows10-x64-v7.6.5.32.zip",
                  "c7401514a6d7d24e8541f88c12e4328f165b5c5afd010ee462d356cac2158268")
]

include("../common.jl")
