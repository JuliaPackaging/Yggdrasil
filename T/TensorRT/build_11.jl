platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.0.3/tars/TensorRT-8.0.3.4.Linux.x86_64-gnu.cuda-11.3.cudnn8.2.tar.gz",
                      "3177435024ff4aa5a6dba8c1ed06ab11cc0e1bf3bb712dfa63a43422f41313f3")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.0.3/zip/TensorRT-8.0.3.4.Windows10.x86_64.cuda-11.3.cudnn8.2.zip",
                      "a347d6e7981d0497ba60c5de78716101d73105946e1ff745f0f426f51ea691b0")],
)
