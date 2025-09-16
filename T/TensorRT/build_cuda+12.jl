platforms_and_sources = Dict(
    Platform("aarch64", "linux"; cuda_platform="jetson") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.7.0/tars/TensorRT-10.7.0.23.l4t.aarch64-gnu.cuda-12.6.tar.gz",
                      "b3028a82818a9daf6296f43d0cdecfa51eaea4552ffb6fe6fad5e6e1aea44da6")],
    Platform("aarch64", "linux"; cuda_platform="sbsa") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.7.0/tars/TensorRT-10.7.0.23.Linux.aarch64-gnu.cuda-12.6.tar.gz",
                      "6b304cf014f2977e845bd44fdb343f0e7af2d9cded997bc9cfea3949d9e84dcb")],
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.7.0/tars/TensorRT-10.7.0.23.Linux.x86_64-gnu.cuda-12.6.tar.gz",
                      "d7f16520457caaf97ad8a7e94d802f89d77aedf9f361a255f2c216e2a3a40a11")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.7.0/zip/TensorRT-10.7.0.23.Windows.win10.cuda-12.6.zip",
                      "fbdef004578e7ccd5ee51fe7f846b57422364a743372fd8f9f1d7dbd33f62879")],
)
