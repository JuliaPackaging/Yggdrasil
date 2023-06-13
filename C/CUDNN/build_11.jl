platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.2/local_installers/11.x/cudnn-linux-x86_64-8.9.2.26_cuda11-archive.tar.xz",
                      "39883d1bcab4bd2bf3dac5a2172b38533c1e777e45e35813100059e5091406f6")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.2/local_installers/11.x/cudnn-linux-ppc64le-8.9.2.26_cuda11-archive.tar.xz",
                      "cc3267d7a6016949fa62a8f48184a7316a4798f0c192809c8184e441778fe0ce")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.2/local_installers/11.x/cudnn-linux-sbsa-8.9.2.26_cuda11-archive.tar.xz",
                      "ad0a45a7992fe165fef3c8be5eef4080ebad19a2334c29dfb01d605776927293")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.2/local_installers/11.x/cudnn-windows-x86_64-8.9.2.26_cuda11-archive.zip",
                      "d3daa2297917333857eaaba1213dd9fc05c099d94e88663274a0f37a4e9baf9d")],
)
