platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.2/tars/TensorRT-8.2.2.1.Linux.x86_64-gnu.cuda-10.2.cudnn8.2.tar.gz",
                      "3be2461e5ad89af6ea5aae9d431fc4671b955fce639d028d250c7a24869b3324")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.2/zip/TensorRT-8.2.2.1.Windows10.x86_64.cuda-10.2.cudnn8.2.zip",
                      "1a3aaeea1db86937bfb2b299c90ed4aae7cd9f7544ba34947cd9ba0d4200a8cf")],
)
