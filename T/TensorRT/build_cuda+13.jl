platforms_and_sources = Dict(
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.16.1/tars/TensorRT-10.16.1.11.Linux.aarch64-gnu.cuda-13.2.tar.gz",
                      "63ecfb16d2df932cc5c3f2a362ae6281919f565c5ca3a5e1299c95780e165c91")],
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.16.1/tars/TensorRT-10.16.1.11.Linux.x86_64-gnu.cuda-13.2.tar.gz",
                      "08334948c57c3bcf2de171ef4bd53d15f48a61a942b048abea12e32f892284e8")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.16.1/zip/TensorRT-10.16.1.11.Windows.amd64.cuda-13.2.zip",
                      "7c853a0e8e9e65935add3d20f89ebfa1971f8e5ab5dce25d4532aecda52c232b")],
)
