using BinaryBuilder

cuda_version = v"11.0.3"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.4/11.0_20200923/cudnn-11.0-linux-x64-v8.0.4.30.tgz",
                  "38a81a28952e314e21577432b0bab68357ef9de7f6c8858f721f78df9ee60c35")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.4/11.0_20200923/cudnn-11.0-linux-ppc64le-v8.0.4.30.tgz",
                  "8da8ed689b1a348182ddd3f59b6758a502e11dc6708c33f96e3b4a40e033d2e1")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.4/11.0_20200923/cudnn-11.0-windows-x64-v8.0.4.30.zip",
                  "1b1438b828ce61888b7f1ed3ac506b32137425dd48aed8bc71abd5d4a7006143")
]

include("../common.jl")
