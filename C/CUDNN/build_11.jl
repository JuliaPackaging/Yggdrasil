platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.4/11.4_20210831/cudnn-11.4-linux-x64-v8.2.4.15.tgz",
                      "0e5d2df890b9967efa6619da421310d97323565a79f05a1a8cb9b7165baad0d7")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.4/11.4_20210831/cudnn-11.4-linux-ppc64le-v8.2.4.15.tgz",
                      "af8749ca83fd6bba117c8bee31b787b7f204946e864294030ee0091eb7d3577e")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.4/11.4_20210831/cudnn-11.4-linux-aarch64sbsa-v8.2.4.15.tgz",
                      "48b11f19e9cd3414ec3c6c357ad228aebbd43282aae372d42cab2af67c32a08b")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.4/11.4_20210831/cudnn-11.4-windows-x64-v8.2.4.15.zip",
                      "f01594639de35c380b4e360673ccaf04cdb238578e4b284935ee3d5a45f51f3c")],
)
