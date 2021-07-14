platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/2.9.9/agnostic/x64/nccl_2.9.9-1+cuda11.0_x86_64.txz",
                      "32dce9f1759f800e6d4e81eabcb70a8ffc9dc6b56abb339a13db9d991f6e7252")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/2.9.9/agnostic/ppc64le/nccl_2.9.9-1+cuda11.0_ppc64le.txz",
                      "5481f52b800bce132570246f75bafad3a23f8e56ea887536f427a4eb21f82b69")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/2.9.9/agnostic/aarch64sbsa/nccl_2.9.9-1+cuda11.0_aarch64.txz",
                      "c94bfa1bf12730f1e998c503a7951df4a5ea89e03a8fc27fcfd4a3e264355a40")],
)
