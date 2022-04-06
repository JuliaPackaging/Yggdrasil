platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.4/10.2_20210831/cudnn-10.2-linux-x64-v8.2.4.15.tgz",
                      "d23c94a3115a1c77116a6c127d9175fbf59f723364374f26a34699075f3222f1")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.4/10.2_20210831/cudnn-10.2-windows10-x64-v8.2.4.15.zip",
                      "a13eb10cfd7e6b7b8f39d8593038855b911012c29f03990878622bdae873c4a8")],
    Platform("aarch64", "linux") => [
        FileSource("https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/arm64/libcudnn8_8.2.4.15-1+cuda10.2_arm64.deb", "3f08dbe14c3becb9fa1ed85cd4a080efb30edb0c4beb2fc1a2e14da3f2eefb79"),
        FileSource("https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/arm64/libcudnn8-dev_8.2.4.15-1+cuda10.2_arm64.deb", "4816575e8a14baf3fc1619cb01c6dc2afd4f1b39210079d271208088ecc48702")
    ]
)
