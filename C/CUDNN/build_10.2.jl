platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.1.32/10.2_06072021/cudnn-10.2-linux-x64-v8.2.1.32.tgz",
                      "fd6321ff3bce4ce0cb3342e5bd38c96dcf3b073d44d0808962711c518b6d61e2")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.1.32/10.2_06072021/cudnn-10.2-windows10-x64-v8.2.1.32.zip",
                      "3e70876bdcf44f856d9c9dbdbde07ceec43005e97d5ffe83338b255c8466151f")],
    Platform("aarch64", "linux") => [
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cudnn/libcudnn8_8.2.1.32-1+cuda10.2_arm64.deb", "4c1619640e5411fb53e87828c62ff429daa608c8f02efb96460b43f743d64bb8"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cudnn/libcudnn8-dev_8.2.1.32-1+cuda10.2_arm64.deb", "adf7873edbde7fe293f672ebc65fcec299642950797d18b1c3a89855bb23904e")
    ]
)
