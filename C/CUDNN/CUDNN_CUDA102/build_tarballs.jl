using BinaryBuilder

cuda_version = v"10.2.89"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.1.13/10.2_20200626/cudnn-10.2-linux-x64-v8.0.1.13.tgz",
                  "0c106ec84f199a0fbcf1199010166986da732f9b0907768c9ac5ea5b120772db")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.1.13/10.2_20200626/cudnn-10.2-linux-ppc64le-v8.0.1.13.tgz",
                  "0e15a28b4bb1fb97370f406deb14af2deb3e1670d330b5c148cbf7d3c1ff7e0e")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.1.13/10.2_20200626/cudnn-10.2-windows-x64-v8.0.1.13.zip",
                  "88382786d0974a786f0b643bb30ed6182e69f04ddbc3228e54ad7509997a11b2")
]

include("../common.jl")
