platforms_and_sources = Dict(
    Platform("aarch64", "linux"; cuda_platform="jetson") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.5.0/tars/TensorRT-10.5.0.18.l4t.aarch64-gnu.cuda-12.6.tar.gz",
                      "9f039b38db99dc0ff8994dab3b71653faca6a1a4f42bbe13140c679072d7b5cb")],
    Platform("aarch64", "linux"; cuda_platform="sbsa") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.5.0/tars/TensorRT-10.5.0.18.Ubuntu-24.04.aarch64-gnu.cuda-12.6.tar.gz",
                      "c306bb5d01e496fc20728d3a1a30731f6f1a7c33f92a2726ff2cc8e110906683")],
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.5.0/tars/TensorRT-10.5.0.18.Linux.x86_64-gnu.cuda-12.6.tar.gz",
                      "f404d379d639552a3e026cd5267213bd6df18a4eb899d6e47815bbdb34854958")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.5.0/zip/TensorRT-10.5.0.18.Windows.win10.cuda-12.6.zip",
                      "e6436f4164db4e44d727354dccf7d93755efb70d6fbfd6fa95bdfeb2e7331b24")],
)
