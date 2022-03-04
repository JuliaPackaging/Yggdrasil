platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.11.4/agnostic/x64/nccl_2.11.4-1+cuda11.0_x86_64.txz",
                      "45e0a7bfabcedca068576e9decd0bb733d8840816d5dc7bd4c235f8b2e736a28")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.11.4/agnostic/ppc64le/nccl_2.11.4-1+cuda11.0_ppc64le.txz",
                      "d593b6b204f71a323e477463faf3ebcfadb2561dd5f7b0237c482a16bb791714")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.11.4/agnostic/aarch64sbsa/nccl_2.11.4-1+cuda11.0_aarch64.txz",
                      "c4a4c90c340e89baa06a4e2c16276cbfe221578e51c88c9001205a0a93032d4f")],
)
