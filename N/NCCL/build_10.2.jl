platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.11.4/agnostic/x64/nccl_2.11.4-1+cuda10.2_x86_64.txz",
                      "d2f59b9385cb2026d9a8d4dee607f9aa93356761257fd57487f81de8563c8da1")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.11.4/agnostic/ppc64le/nccl_2.11.4-1+cuda10.2_ppc64le.txz",
                      "78b9b08d0d943239706c82db12c23e098ee2094108462055e03d74bc1a364601")],
)
