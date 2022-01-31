platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.0.1/tars/TensorRT-8.0.1.6.Linux.x86_64-gnu.cuda-10.2.cudnn8.2.tar.gz",
                      "110bbfd69fe27e298e1ad1bc35300569069ffeb8b691f48bcaf34703e1bafb96")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.0.1/zip/TensorRT-8.0.1.6.Windows10.x86_64.cuda-10.2.cudnn8.2.zip",
                      "003cd632d978205de8b3140da743a9d39647ccb9959a1c219d34201d75a0a49e")],
)
