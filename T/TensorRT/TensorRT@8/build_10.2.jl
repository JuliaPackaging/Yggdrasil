platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.1/tars/TensorRT-8.2.1.8.Linux.x86_64-gnu.cuda-10.2.cudnn8.2.tar.gz",
                      "96160493b88526f4eb136b29399c3c8bb2ef5e2dd4f8325a44104add10edd35b")],
    Platform("aarch64", "linux") => [
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvinfer-bin_8.2.1-1+cuda10.2_arm64.deb", "738904f63c16498da9e9789dd4c99a9be926a2809c30cb45c2a97877b6e3c3d7"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvinfer-dev_8.2.1-1+cuda10.2_arm64.deb", "54c79348f364731d90aa857597185d73067864e208fb24a8fb7675405661c6d6"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvinfer-plugin-dev_8.2.1-1+cuda10.2_arm64.deb", "e357606f5884608cbb07a0dfe64c48490746e90e6eaf91bbed2324623e368b7c"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvinfer-plugin8_8.2.1-1+cuda10.2_arm64.deb", "ea0bcf03218d1c22fdb563f3db45e00829234712f05ce71866c9486bc1dcadaf"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvinfer8_8.2.1-1+cuda10.2_arm64.deb", "af79b941988fff6daec89a663fd5bc12541df8c568e4e0c66c4e1991ec4c923c"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvonnxparsers-dev_8.2.1-1+cuda10.2_arm64.deb", "e50047d41ceb8341bdaa67f9df3e365257d80b520ba68af340b18ec8a238366b"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvonnxparsers8_8.2.1-1+cuda10.2_arm64.deb", "d7c27711b73e4cc3febb21969d21a84cd92e21a7863da75d0a72b50ea2c12833"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvparsers-dev_8.2.1-1+cuda10.2_arm64.deb", "816c0f9daa031be52e873907662c26d8d58e29cc2603a5d7ba1e60a0d76d00fd"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvparsers8_8.2.1-1+cuda10.2_arm64.deb", "f2ab966c85b6e8a36098a6bc05e0ac478bd1cc9d966373223c0ec56dc73d302b"),
    ],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.1/zip/TensorRT-8.2.1.8.Windows10.x86_64.cuda-10.2.cudnn8.2.zip",
                      "d00f9d6f0d75d572f4b5a0041408650138f4f3aac76902cbfd1580448f75ee47")],
)
