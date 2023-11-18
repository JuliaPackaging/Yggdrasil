platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/x64/nccl_$(version)-1+cuda11.0_x86_64.txz",
                      "9e8db61e16db0ed937bd116471ad4963f83d3dab588f9b8fb499a869a3fbe374")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/ppc64le/nccl_$(version)-1+cuda11.0_ppc64le.txz",
                      "70d5156fa8908182d88be9dd0007b4f8fb6bc92509846b7c2579179f6fbe3595")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/aarch64sbsa/nccl_$(version)-1+cuda11.0_aarch64.txz",
                      "2b7ba3a646fdcac66544e99b39cb1720c7b6eaa74a89f753413dcbb450bd4c36")],
)
