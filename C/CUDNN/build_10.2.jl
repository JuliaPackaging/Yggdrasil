platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.0.53/10.2_04222021/cudnn-10.2-linux-x64-v8.2.0.53.tgz",
                      "6ecbc98b3795e940ce0831ffb7cd2c0781830fdd6b1911f950bcaf6d569f807c")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.0.53/10.2_04222021/cudnn-10.2-windows10-x64-v8.2.0.53.zip",
                      "1dc2182e2c8ff995e81cf812dd81d628fc5e4b9bcd5eb838ac71acc2928409d8")],
)
