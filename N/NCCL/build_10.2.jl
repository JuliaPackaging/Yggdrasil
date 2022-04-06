platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.12.7/agnostic/x64/nccl_2.12.7-1+cuda10.2_x86_64.txz",
                      "922b875850e25d209e0c73da7f2f123e6c88a2667002af7212295797401da7ee")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.12.7/agnostic/ppc64le/nccl_2.12.7-1+cuda10.2_ppc64le.txz",
                      "870185ba54e6e1aee0909ea2f43cea6b643a8da15d033d62b5e0867c8ad35d8e")],
)
