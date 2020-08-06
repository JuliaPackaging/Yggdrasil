using BinaryBuilder

cuda_version = v"10.2.89"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.2.39/10.2_20200626/cudnn-10.2-linux-x64-v8.0.2.39.tgz",
                  "c9cbe5c211360f3cfbc0fb104f0e9096b37e53f89392525679f049276b2f701f")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.2.39/10.2_20200626/cudnn-10.2-linux-ppc64le-v8.0.2.39.tgz",
                  "c32325ff84a8123491f2e58b3694885a9a672005bc21764b38874688c0e43262")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.2.39/10.2_20200626/cudnn-10.2-windows10-x64-v8.0.2.39.zip",
                  "ba7d544fba2aaa7e6445cc41d6890a890567ea14ca942c13115f7d5654ea451f")
]

include("../common.jl")
