platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.2/11.4_07062021/cudnn-11.4-linux-x64-v8.2.2.26.tgz",
                      "fbc631ce19688e87d7d2420403b20db97885b17f718f0f51d7e9fc0905d86e07")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.2/11.4_07062021/cudnn-11.4-linux-ppc64le-v8.2.2.26.tgz",
                      "b11b9e515a86978dc21ab50a7d2320bfb505cbce9dffa25480225c597c682b43")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.2/11.4_07062021/cudnn-11.4-linux-aarch64sbsa-v8.2.2.26.tgz",
                      "e240d45d79eecb2257fcb8a219324f19d8e2d6e145fbd035a38d267580d65e9a")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.2/11.4_07062021/cudnn-11.4-windows-x64-v8.2.2.26.zip",
                      "fce18f1f515a480e33fa3df8bfd8616463ee44b101e6e149d46f29a66c1c306e")],
)
