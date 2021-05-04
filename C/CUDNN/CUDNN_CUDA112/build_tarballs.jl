using BinaryBuilder

cuda_version = v"11.2.0"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.1.0.77/11.2_20210127/cudnn-11.2-linux-x64-v8.1.0.77.tgz",
                  "dbe82faf071d91ba9bcf00480146ad33f462482dfee56caf4479c1b8dabe3ecb")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.1.0.77/11.2_20210127/cudnn-11.2-linux-ppc64le-v8.1.0.77.tgz",
                  "0d3f8fa21959e9f94889841cc8445aecf41d2f3c557091b447313afb43034037")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.1.0.77/11.2_20210127/cudnn-11.2-windows-x64-v8.1.0.77.zip",
                  "f5a23402ebed5b2add2ae0dc79df42f055f5851bbb3b1d0f6aa9dcdeeb9346ce")
]

include("../common.jl")

# bump

