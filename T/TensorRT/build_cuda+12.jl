platforms_and_sources = Dict(
    # 10.7 is the last TensorRT for JetPack 6
    Platform("aarch64", "linux"; cuda_platform="jetson") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.7.0/tars/TensorRT-10.7.0.23.l4t.aarch64-gnu.cuda-12.6.tar.gz",
                      "b3028a82818a9daf6296f43d0cdecfa51eaea4552ffb6fe6fad5e6e1aea44da6")],
    Platform("aarch64", "linux"; cuda_platform="sbsa") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.13.0/tars/TensorRT-10.13.0.35.Linux.aarch64-gnu.cuda-12.9.tar.gz",
                      "b2f7c7ae6da3588729b7a64825246cc59b643adbe373684fb9c5713262ed46c2")],
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.16.1/tars/TensorRT-10.16.1.11.Linux.x86_64-gnu.cuda-12.9.tar.gz",
                      "48e64fc9231fe3aeaa18be13385b486ea7c7131dd64f09b54e5fcb051386f014")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.16.1/zip/TensorRT-10.16.1.11.Windows.amd64.cuda-12.9.zip",
                      "80bbe8e07a4fccde33ae7d210ffc0e6d1af96dae5ffaaeed60209f775fbf4275")],
)
