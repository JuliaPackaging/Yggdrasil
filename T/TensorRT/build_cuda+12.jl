platforms_and_sources = Dict(
    # 10.7 is the last TensorRT for JetPack 6
    Platform("aarch64", "linux"; cuda_platform="jetson") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.7.0/tars/TensorRT-10.7.0.23.l4t.aarch64-gnu.cuda-12.6.tar.gz",
                      "b3028a82818a9daf6296f43d0cdecfa51eaea4552ffb6fe6fad5e6e1aea44da6")],
    Platform("aarch64", "linux"; cuda_platform="sbsa") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.13.0/tars/TensorRT-10.13.0.35.Linux.aarch64-gnu.cuda-12.9.tar.gz",
                      "b2f7c7ae6da3588729b7a64825246cc59b643adbe373684fb9c5713262ed46c2")],
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.13.0/tars/TensorRT-10.13.0.35.Linux.x86_64-gnu.cuda-12.9.tar.gz",
                      "899ff39e237f1351fccac7f6891617f68cbab71c13a7d7c703184424bdbbf621")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.13.0/zip/TensorRT-10.13.0.35.Windows.win10.cuda-12.9.zip",
                      "8b280dcdb9ce0bebed512ecb4cf8feaf5bd61dea9c981d5fc1fabfae7d06614f")],
)
