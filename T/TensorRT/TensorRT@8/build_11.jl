platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.1/tars/TensorRT-8.2.1.8.Linux.x86_64-gnu.cuda-11.4.cudnn8.2.tar.gz",
                      "3e9a9cc4ad0e5ae637317d924dcddf66381f4db04e2571f0f2e6ed5a2a51f247")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.1/tars/TensorRT-8.2.1.8.Ubuntu-20.04.aarch64-gnu.cuda-11.4.cudnn8.2.tar.gz",
                      "7c21312bf552904339d5f9270dc40c39321558e5993d93e4f94a0ed47d9a8a79")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.1/zip/TensorRT-8.2.1.8.Windows10.x86_64.cuda-11.4.cudnn8.2.zip",
                      "a900840f3839ae14fbd9dc837eb6335d3cb4f217f1f29604ef72fa88e8994bcd")],
)
