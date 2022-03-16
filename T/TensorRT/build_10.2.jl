platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.0.1/tars/TensorRT-8.0.1.6.Linux.x86_64-gnu.cuda-10.2.cudnn8.2.tar.gz",
                      "110bbfd69fe27e298e1ad1bc35300569069ffeb8b691f48bcaf34703e1bafb96")],
    Platform("aarch64", "linux") => [
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvinfer-bin_8.0.1-1+cuda10.2_arm64.deb", "f4a98ac9086b4a195bcab26aca176a9db6b5a196ff42d3dfdb28a16d30e8a312"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvinfer-dev_8.0.1-1+cuda10.2_arm64.deb", "f750c910a23107715dc2510d360725e46e9072079caacf3cec4255dd38bee849"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvinfer-plugin-dev_8.0.1-1+cuda10.2_arm64.deb", "4dabae4f5ea8f3eb54dbd36cf3dde3d038fae2a857529b869844b05cec77092a"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvinfer-plugin8_8.0.1-1+cuda10.2_arm64.deb", "71435b08b97346e2b0f568332c3440b8f6c00b5198f83ab5935f161aae39f8d8"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvinfer8_8.0.1-1+cuda10.2_arm64.deb", "305c4482a315ceb59e514823b359fdeebfbdd5fa2124e277dd176589e2f49aea"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvonnxparsers-dev_8.0.1-1+cuda10.2_arm64.deb", "6f477ab54c4fd646ab9f65baed0157dca7ca29de6bc7f992f5285d8baa30b5eb"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvonnxparsers8_8.0.1-1+cuda10.2_arm64.deb", "8d4b0722515d91592e73dca2c43b798430bef4633b34d912324b53b63acf41ae"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvparsers-dev_8.0.1-1+cuda10.2_arm64.deb", "b09864c351aebf2200fb98f48dc68b4a75260bbcd01423bbf1633acdc115b9be"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/t/tensorrt/libnvparsers8_8.0.1-1+cuda10.2_arm64.deb", "34040352c9f44611928a7d6aa6a7f885b6506a7b3310a8b9fc0782a9ba42037a"),
    ],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.0.1/zip/TensorRT-8.0.1.6.Windows10.x86_64.cuda-10.2.cudnn8.2.zip",
                      "003cd632d978205de8b3140da743a9d39647ccb9959a1c219d34201d75a0a49e")],
)
