using BinaryBuilder

cuda_version = v"9.2.148"   # NOTE: could be less specific

sources_linux = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/9.2_20191031/cudnn-9.2-linux-x64-v7.6.5.32.tgz",
                  "a2a2c7a8ba7b16d323b651766ee37dcfdbc2b50d920f73f8fde85005424960e4")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/9.2_20191031/cudnn-9.2-windows10-x64-v7.6.5.32.zip",
                  "ffa553df2e9af1703bb7786a784356989dac5c415bf5bca73e52b1789ddd4984")
]

include("../common.jl")
