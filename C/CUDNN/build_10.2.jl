platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.1/local_installers/10.2/cudnn-linux-x86_64-8.3.1.22_cuda10.2-archive.tar.xz",
                      "5982bb96c2a720268fa44b908feb5258d060ad47f1f6e6030e760d13195ea964")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.1/local_installers/10.2/cudnn-windows-x86_64-8.3.1.22_cuda10.2-archive.zip",
                      "83797cac5c1e6c59bcf6bcd13ae23a3d00f909b19295819fb50063ea3356fadc")],
)
