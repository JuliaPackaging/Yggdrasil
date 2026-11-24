platforms_and_sources = Dict(
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.13.3/tars/TensorRT-10.13.3.9.Linux.aarch64-gnu.cuda-13.0.tar.gz",
                      "d84688ad5b313fc0090625c4401a6070d8336f71b4c9589150de3d23172f60f4")],
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.13.3/tars/TensorRT-10.13.3.9.Linux.x86_64-gnu.cuda-13.0.tar.gz",
                      "897261be948962c9eb5d3595625f91d85a9aa8b57601aed6efac3fd6d9ff6f53")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.13.3/zip/TensorRT-10.13.3.9.Windows.win10.cuda-13.0.zip",
                      "10ada15b14498e0ec8556cb19433129fd362a8e3debf75db06ccacd8659d9662")],
)
