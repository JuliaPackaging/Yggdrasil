platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.0.3/tars/TensorRT-8.0.3.4.Linux.x86_64-gnu.cuda-10.2.cudnn8.2.tar.gz",
                      "2f17178307b538245fc03b04b0d2c891e36c39cc772ae1794a3fa0d9d63a583d")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.0.3/zip/TensorRT-8.0.3.4.Windows10.x86_64.cuda-10.2.cudnn8.2.zip",
                      "315c2bd6a2257f4fef8662d0cc4c73ae41e6641f6a3ef6227eb43b0f89abf68a")],
)
