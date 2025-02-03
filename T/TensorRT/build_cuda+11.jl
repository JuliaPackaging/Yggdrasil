platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.4.0/tars/TensorRT-10.4.0.26.Linux.x86_64-gnu.cuda-11.8.tar.gz",
                      "7cd001fcb10937a65201f253c2f3fece9eb0957f80977bf39a8952f4ef7ff0bb")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.4.0/zip/TensorRT-10.4.0.26.Windows.win10.cuda-11.8.zip",
                      "a59cafbab4336253ae89cbb5255d7908ffd3673444ce998a1312ceaa771208cb")],
)
