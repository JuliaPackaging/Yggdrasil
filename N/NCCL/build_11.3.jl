platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/2.9.9/agnostic/x64/nccl_2.9.9-1+cuda11.3_x86_64.txz",
                      "59df720e039fd8a765ceb94749e0a8ca9d7bb3dd9bec4867f500e8f0325262c8")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/2.9.9/agnostic/ppc64le/nccl_2.9.9-1+cuda11.3_ppc64le.txz",
                      "11dec74b9397c100588dcc96a8c23ffc89567523d47047bcf5d12f625c1c13b6")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/2.9.9/agnostic/aarch64sbsa/nccl_2.9.9-1+cuda11.3_aarch64.txz",
                      "b3291328990785807ba01d20a730bed86fbf84d28194da7e8194c9503d0eaefe")],
)
