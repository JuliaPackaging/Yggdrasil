platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.11.4/agnostic/x64/nccl_2.11.4-1+cuda11.4_x86_64.txz",
                      "639a86d7f90a0b9f8143ef2044b9cdccd7de51b28cccce2f9852d3bdd0e4d114")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.11.4/agnostic/ppc64le/nccl_2.11.4-1+cuda11.4_ppc64le.txz",
                      "6347d56c6e13fc321858fd8779741c62ac0bf55a13ab57d39e2780d62181a6b4")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.11.4/agnostic/aarch64sbsa/nccl_2.11.4-1+cuda11.4_aarch64.txz",
                      "4bef02db97ef45146b80e3d20218198f57cd24f115624f50c5eca06fff3f216f")],
)
