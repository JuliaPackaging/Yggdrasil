platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.2/tars/TensorRT-8.2.2.1.Linux.x86_64-gnu.cuda-11.4.cudnn8.2.tar.gz",
                      "da130296ac6636437ff8465812eb55dbab0621747d82dc4fe9b9376f00d214af")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.2/tars/TensorRT-8.2.2.1.Ubuntu-20.04.aarch64-gnu.cuda-11.4.cudnn8.2.tar.gz",
                      "ed3bea21f44da7b43e93803a1e0ce0f4d68678afe5c7c0393b3e41d5c099555c")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.2/zip/TensorRT-8.2.2.1.Windows10.x86_64.cuda-11.4.cudnn8.2.zip",
                      "9efd246b1f518314f8912c6997fe8064ee9d557ae01665c2c4cb4f1a11ed8865")],
)
