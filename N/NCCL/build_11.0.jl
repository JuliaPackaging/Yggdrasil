platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.12.7/agnostic/x64/nccl_2.12.7-1+cuda11.0_x86_64.txz",
                      "1fa8c1e84ab7f9b571b27b58fad9212d111e7007a76d60aac4c1ed63cd616873")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.12.7/agnostic/ppc64le/nccl_2.12.7-1+cuda11.0_ppc64le.txz",
                      "d904446e657e5f4edf06250f780197709682cf4a4e8cbef51f1864e7122712f7")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.12.7/agnostic/aarch64sbsa/nccl_2.12.7-1+cuda11.0_aarch64.txz",
                      "804683c113f6879b0197a0ba60a3cdef3d7465634e83b09b2a2aa38027ceeb58")],
)
