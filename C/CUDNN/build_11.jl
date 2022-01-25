platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.2/local_installers/11.5/cudnn-linux-x86_64-8.3.2.44_cuda11.5-archive.tar.xz",
                      "5500953c08c5e5d1dddcfda234f9efbddcdbe43a53b26dc0a82c723fa170c457")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.2/local_installers/11.5/cudnn-linux-ppc64le-8.3.2.44_cuda11.5-archive.tar.xz",
                      "0581bce48023a3ee71c3a819aaefcabe693eca18b61e2521dc5f8e6e71567b1b")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.2/local_installers/11.5/cudnn-linux-sbsa-8.3.2.44_cuda11.5-archive.tar.xz",
                      "7eb8c96bfeec98e8aa7cea1e95633d2a9481fc99040eb0311d31bf137a7aa6ea")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.3.2/local_installers/11.5/cudnn-windows-x86_64-8.3.2.44_cuda11.5-archive.zip",
                      "9e36eef803f1cf9ab24846dc133a3014fdc548775ee29073e8466d415957a1c0")],
)
