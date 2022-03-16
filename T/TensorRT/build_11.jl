platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.3/tars/TensorRT-8.2.3.0.Linux.x86_64-gnu.cuda-11.4.cudnn8.2.tar.gz",
                      "207c0c4820e5acf471925b7da4c59d48c58c265a27d88287c4263038c389e106")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.3/tars/TensorRT-8.2.3.0.Ubuntu-20.04.aarch64-gnu.cuda-11.4.cudnn8.2.tar.gz",
                      "6f18651b153d2ce97ccc4556b8dd11847bde177336767487e1a22095e3c16c08")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.3/zip/TensorRT-8.2.3.0.Windows10.x86_64.cuda-11.4.cudnn8.2.zip",
                      "f3aa6ebe5d554b10e5b7bb4db9357b25746a600b95e17f3cf49686cfeeddb0ff")],
)
