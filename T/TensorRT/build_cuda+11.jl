platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.5.0/tars/TensorRT-10.5.0.18.Linux.x86_64-gnu.cuda-11.8.tar.gz",
                      "ca37e6752e8182173aa18051a21c3082f8fdcb9995951e0ed0a8c2395f6f77b3")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.5.0/zip/TensorRT-10.5.0.18.Windows.win10.cuda-11.8.zip",
                      "9e83c1c877ee9b36e916adaaf8af009c6bddc05529b7f8ad0e8a39f582d92f93")],
)
