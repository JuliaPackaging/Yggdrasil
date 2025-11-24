platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.7.0/tars/TensorRT-10.7.0.23.Linux.x86_64-gnu.cuda-11.8.tar.gz",
                      "958e1c32b48e41d1c48bdc94363450e14f996ca9de0e205ccee65af319eea2c0")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.7.0/zip/TensorRT-10.7.0.23.Windows.win10.cuda-11.8.zip",
                      "fd6ec60f8fc48cdd050fbcc632473b42c28a217f0ec44e0177c4cc9a18c77af8")],
)
