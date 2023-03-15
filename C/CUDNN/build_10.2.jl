platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.6.0/local_installers/10.2/cudnn-linux-x86_64-8.6.0.163_cuda10-archive.tar.xz",
                      "b78b2bfc6ac5aaa771bb6561689424e4ad579bfd255387215c6f2154bd3d47d9")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.6.0/local_installers/10.2/cudnn-windows-x86_64-8.6.0.163_cuda10-archive.zip",
                      "fa34d362b8d61e33a20da2a5b91dbd72e5b6db5b53fd77900b3363f29ee9ccd9")],
)
