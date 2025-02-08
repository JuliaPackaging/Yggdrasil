platforms_and_sources = Dict(
    Platform("aarch64", "linux"; cuda_platform="jetson") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.4.0/tars/TensorRT-10.4.0.26.l4t.aarch64-gnu.cuda-12.6.tar.gz",
                      "bf6a5bd6899d1ab2a5137a9a26c0cfc2472109a8e10fafef283871ea150dcd76")],
    Platform("aarch64", "linux"; cuda_platform="sbsa") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.4.0/tars/TensorRT-10.4.0.26.Ubuntu-24.04.aarch64-gnu.cuda-12.6.tar.gz",
                      "1fe1061a0a33522b12fbc8ba5cea35a49acff93b5cf11161e3f20cf8019f3951")],
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.4.0/tars/TensorRT-10.4.0.26.Linux.x86_64-gnu.cuda-12.6.tar.gz",
                      "cb0273ecb3ba4db8993a408eedd354712301a6c7f20704c52cdf9f78aa97bbdb")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.4.0/zip/TensorRT-10.4.0.26.Windows.win10.cuda-12.6.zip",
                      "3a7de83778b9e9f812fd8901e07e0d7d6fc54ce633fcff2e340f994df2c6356c")],
)
