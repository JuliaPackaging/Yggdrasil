using BinaryBuilder

cuda_version = v"11.0.2"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.2.39/11.0_20200626/cudnn-11.0-linux-x64-v8.0.2.39.tgz",
                  "672f46288b8edd98f8d156a4f1ff518201ca6de0cff67915ceaa37f6d6d86345")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.2.39/11.0_20200626/cudnn-11.0-linux-ppc64le-v8.0.2.39.tgz",
                  "b7c1ce5b1191eb007ba3455ea5f497fdce293a646545d8a6ed93e9bb06d7f057")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.2.39/11.0_20200626/cudnn-11.0-windows-x64-v8.0.2.39.zip",
                  "3e340edba0b9ce7ad35d8e77cbaee868bba3e4394a3435bd4fa27c81f261ca4c")
]

include("../common.jl")
