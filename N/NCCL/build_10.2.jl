platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/2.9.9/agnostic/x64/nccl_2.9.9-1+cuda10.2_x86_64.txz",
                      "c8ad6b2cddfb423c6dc78177fa70c4e14d770cc24b4c9b3985aa2ca36759a2cc")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/2.9.9/agnostic/ppc64le/nccl_2.9.9-1+cuda10.2_ppc64le.txz",
                      "2f39267e5fb2fd03949b7ff62bccfbbaf0f57f4e5d429b976b2f34339b444977")],
)
