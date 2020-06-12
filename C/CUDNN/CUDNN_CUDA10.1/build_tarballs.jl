using BinaryBuilder

cuda_version = v"10.1.243"  # NOTE: could be less specific

sources_linux = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/10.1_20191031/cudnn-10.1-linux-x64-v7.6.5.32.tgz",
                  "7eaec8039a2c30ab0bc758d303588767693def6bf49b22485a2c00bf2e136cb3")
]
sources_macos = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/10.1_20191031/cudnn-10.1-osx-x64-v7.6.5.32.tgz",
                  "8ecce28a5ed388a2b9b2d239e08d7c550f53b79288e6d9e5eb4c152bfc711aff")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/10.1_20191031/cudnn-10.1-windows10-x64-v7.6.5.32.zip",
                  "5e4275d738cc3a105cf6558b70b8a2ff514989ca1cd17bc8515086e20561a652")
]

include("../common.jl")
