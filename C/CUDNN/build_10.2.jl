platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.2/10.2_07062021/cudnn-10.2-linux-x64-v8.2.2.26.tgz",
                      "b4a2067774f509e65a1d8ba3bd86162b9e09de5946bb636887b4cc605dddeb6e")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.2/10.2_07062021/cudnn-10.2-windows10-x64-v8.2.2.26.zip",
                      "27dee1094c49f4993754ddecd1e3bf4a14b1d4d43951cc5956d2375eb3bcb9f8")],
)
