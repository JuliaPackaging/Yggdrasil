platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.0.53/11.3_04222021/cudnn-11.3-linux-x64-v8.2.0.53.tgz",
                      "7a195dc93a7cda2bdd4d9b73958d259c784be422cd941a9a625aab75309f19dc")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.0.53/11.3_04222021/cudnn-11.3-linux-ppc64le-v8.2.0.53.tgz",
                      "cfe06735671a41a5e25fc7542d740177ac8eab1ab146bd30f19e0fa836895611")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.0.53/11.3_04222021/cudnn-11.3-windows-x64-v8.2.0.53.zip",
                      "c8f108f8b646fd22ab35da7a7d73e2d977f671a1abd3364d372292102e0d7429")],
)
