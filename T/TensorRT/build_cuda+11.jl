platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.13.0/tars/TensorRT-10.13.0.35.Linux.x86_64-gnu.cuda-11.8.tar.gz",
                      "4128dd4f40433b957c90f9d04d53311d1636ee046b66a241ab60492f4861de74")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.13.0/zip/TensorRT-10.13.0.35.Windows.win10.cuda-11.8.zip",
                      "c786d9300dd6fbc5bae1891aee3648366cba20fb4f3982116c309e88f9797f54")],
)
