platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.2/local_installers/10.2/cudnn-linux-x86_64-8.3.2.44_cuda10.2-archive.tar.xz",
                      "d6f56ef9ca8cf8f91eb73210ba6c3dca49ba4446c1661bfafe55c1ec40b669ac")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.2/local_installers/10.2/cudnn-windows-x86_64-8.3.2.44_cuda10.2-archive.zip",
                      "3810b7a4313614aedd28260785f0ebaa69204bb38fa61e439f75c75a4ba07b3d")],
)
