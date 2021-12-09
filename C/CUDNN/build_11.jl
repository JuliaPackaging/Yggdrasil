platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.1/local_installers/11.5/cudnn-linux-x86_64-8.3.1.22_cuda11.5-archive.tar.xz",
                      "f5ff3c69b6a8a9454289b42eca1dd41c3527f70fcf49428eb80502bcf6b02f6e")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.1/local_installers/11.5/cudnn-linux-ppc64le-8.3.1.22_cuda11.5-archive.tar.xz",
                      "1d2419a20ee193dc6a3a0ba87e79f408286d3d317c9831cbc1f0b7a268c100b0")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.1/local_installers/11.5/cudnn-linux-sbsa-8.3.1.22_cuda11.5-archive.tar.xz",
                      "ff23a881366c0ee79b973a8921c6dd400628a321557550ad4e0a26a21caad263")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.1/local_installers/11.5/cudnn-windows-x86_64-8.3.1.22_cuda11.5-archive.zip",
                      "f0d5cb8d899e5405c00c3ea3925d9143a832ea6239bc70309bb2ded2bfb8d824")],
)
