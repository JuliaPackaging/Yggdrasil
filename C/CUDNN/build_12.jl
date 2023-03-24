platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.8.1/local_installers/12.0/cudnn-linux-x86_64-8.8.1.3_cuda12-archive.tar.xz",
                      "79d77a769c7e7175abc7b5c2ed5c494148c0618a864138722c887f95c623777c")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.8.1/local_installers/12.0/cudnn-linux-ppc64le-8.8.1.3_cuda12-archive.tar.xz",
                      "b0e89021a846952cad8cfc674edce2883f6e344ebd47a2394f706b1136715bc7")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.8.1/local_installers/12.0/cudnn-linux-sbsa-8.8.1.3_cuda12-archive.tar.xz",
                      "9e3977aa1b9d06eb860b582ac8933630675a0243029c259bfec5bb5699867d20")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/downloads/compute/cudnn/secure/8.8.1/local_installers/12.0/cudnn-windows-x86_64-8.8.1.3_cuda12-archive.zip",
                      "ec1a6e1cd98808454b026df0da16bdd08149f2a9120ce8010f55a96e573af9f2")],
)
