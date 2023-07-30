platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.2/local_installers/12.x/cudnn-linux-x86_64-8.9.2.26_cuda12-archive.tar.xz",
                      "ccafd7d15c2bf26187d52d79d9ccf95104f4199980f5075a7c1ee3347948ce32")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.2/local_installers/12.x/cudnn-linux-ppc64le-8.9.2.26_cuda12-archive.tar.xz",
                      "4f5e5bd01570c4805b93fb199f8bb6f8475d016948c55abf48fed9ffe89d13e5")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.2/local_installers/12.x/cudnn-linux-sbsa-8.9.2.26_cuda12-archive.tar.xz",
                      "898d00c82f9ad8797bd6f6c639327b320a38fa4aeebfb2b3fbb2db0d38f7e1b0")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.2/local_installers/12.x/cudnn-windows-x86_64-8.9.2.26_cuda12-archive.zip",
                      "8cf26fec7362d7fac110df9986a579e932a7e1ae693a11e3fa77cca41ae4d8b9")],
)
