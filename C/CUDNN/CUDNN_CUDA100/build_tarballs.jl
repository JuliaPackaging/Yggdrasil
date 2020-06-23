using BinaryBuilder

cuda_version = v"10.0.130"  # NOTE: could be less specific

sources_linux = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/10.0_20191031/cudnn-10.0-linux-x64-v7.6.5.32.tgz",
                   "28355e395f0b2b93ac2c83b61360b35ba6cd0377e44e78be197b6b61b4b492ba")
]
sources_macos = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/10.0_20191031/cudnn-10.0-osx-x64-v7.6.5.32.tgz",
                  "6fa0b819374da49102e285ecf7fcb8879df4d0b3cc430cc8b781cdeb41009b47")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/10.0_20191031/cudnn-10.0-windows10-x64-v7.6.5.32.zip",
                  "2767db23ae2cd869ac008235e2adab81430f951a92a62160884c80ab5902b9e8")
]

include("../common.jl")
