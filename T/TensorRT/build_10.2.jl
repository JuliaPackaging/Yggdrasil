platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.3/tars/TensorRT-8.2.3.0.Linux.x86_64-gnu.cuda-10.2.cudnn8.2.tar.gz",
                      "394dcfa39c8f4cfbcab069e81c5d4ae8c10d64ac3ec70ddc2468a67c930e222b")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.3/zip/TensorRT-8.2.3.0.Windows10.x86_64.cuda-10.2.cudnn8.2.zip",
                      "dc0e70414a11fdc459d338d78b222104198cc1c10789ebefc8aac9de15d9cc3f")],
)
