platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.8.1/local_installers/11.8/cudnn-linux-x86_64-8.8.1.3_cuda11-archive.tar.xz",
                      "af7584cae0cc5524b5913ef08c29ba6154113c60eb0a37a0590a91b515a8a8f9")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.8.1/local_installers/11.8/cudnn-linux-ppc64le-8.8.1.3_cuda11-archive.tar.xz",
                      "d086003d09d5388aa42142f07483a773aa74b602478b0933e24fc63f56f1658f")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.8.1/local_installers/11.8/cudnn-linux-sbsa-8.8.1.3_cuda11-archive.tar.xz",
                      "3b35aaf9a4249886d938d996498c85a19cde9b74657685f2272ec6553e863359")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.8.1/local_installers/11.8/cudnn-windows-x86_64-8.8.1.3_cuda11-archive.zip",
                      "5a22c15bf42f5e74971ac619150829aa954b9e38d5daa7d8483c7cce0d704f2c")],
)
