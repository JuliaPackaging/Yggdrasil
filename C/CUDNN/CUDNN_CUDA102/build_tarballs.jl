using BinaryBuilder

cuda_version = v"10.2.89"   # NOTE: could be less specific

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.4/10.2_20200923/cudnn-10.2-linux-x64-v8.0.4.30.tgz",
                  "c12c69eb16698eacac40aa46b9ce399d4cd86efb6ff0c105142f8a28fcfb980e")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.4/10.2_20200923/cudnn-10.2-linux-ppc64le-v8.0.4.30.tgz",
                  "32a5b92f9e1ef2be90e10f220c4ab144ca59d215eb6a386e93597f447aa6507e")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.0.4/10.2_20200923/cudnn-10.2-windows10-x64-v8.0.4.30.zip",
                  "45dc48f6c19d62e4e4f56da216b72cf69454db374ffb6589aca0cf7c309762fa")
]

include("../common.jl")
