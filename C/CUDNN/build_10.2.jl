platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.2/local_installers/10.2/cudnn-linux-x86_64-8.3.2.44_cuda10.2-archive.tar.xz",
                      "d6f56ef9ca8cf8f91eb73210ba6c3dca49ba4446c1661bfafe55c1ec40b669ac")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.2/local_installers/10.2/cudnn-windows-x86_64-8.3.2.44_cuda10.2-archive.zip",
                      "3810b7a4313614aedd28260785f0ebaa69204bb38fa61e439f75c75a4ba07b3d")],
    Platform("aarch64", "linux") => [
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cudnn/libcudnn8_8.2.1.32-1+cuda10.2_arm64.deb", "4c1619640e5411fb53e87828c62ff429daa608c8f02efb96460b43f743d64bb8"),
        FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cudnn/libcudnn8-dev_8.2.1.32-1+cuda10.2_arm64.deb", "adf7873edbde7fe293f672ebc65fcec299642950797d18b1c3a89855bb23904e")
    ]
)
