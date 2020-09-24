using BinaryBuilder

cuda_version = v"11.0.3"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.3.33/11.0_20200825/cudnn-11.0-linux-x64-v8.0.3.33.tgz",
                  "8924bcc4f833734bdd0009050d110ad0c8419d3796010cf7bc515df654f6065a")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.3.33/11.0_20200825/cudnn-11.0-linux-ppc64le-v8.0.3.33.tgz",
                  "c2d0519831137b43d0eebe07522edb4ef5d62320e65e5d5fa840a9856f25923d")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.3.33/11.0_20200825/cudnn-11.0-windows-x64-v8.0.3.33.zip",
                  "67f64109a677fb43ddbf730b1fbf8f9ba9bf0214d3a9e1027ac546255d4ae3c6")
]

include("../common.jl")
