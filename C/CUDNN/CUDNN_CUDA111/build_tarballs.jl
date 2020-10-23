using BinaryBuilder

cuda_version = v"11.1.0"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.4/11.1_20200923/cudnn-11.1-linux-x64-v8.0.4.30.tgz",
                  "8f4c662343afce5998ce963500fe3bb167e9a508c1a1a949d821a4b80fa9beab")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.4/11.1_20200923/cudnn-11.1-linux-ppc64le-v8.0.4.30.tgz",
                  "b4ddb51610cbae806017616698635a9914c3e1eb14259f3a39ee5c84e7106712")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.4/11.1_20200923/cudnn-11.1-windows-x64-v8.0.4.30.zip",
                  "58bf1fb324d11088a28c3a9f71a38f5dfe167efdf723815dce1867bc03ddaea2")
]

include("../common.jl")
