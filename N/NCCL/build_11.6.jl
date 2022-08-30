platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.12.7/agnostic/x64/nccl_2.12.7-1+cuda11.6_x86_64.txz",
                      "632521d1f1be9322f18234827027c6484beb3ccb35056a21569072c52b4416ce")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.12.7/agnostic/ppc64le/nccl_2.12.7-1+cuda11.6_ppc64le.txz",
                      "b01a3ee30908784c84db2de11765a54a4394267210d2a98a22de542e3695042b")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/nccl/secure/2.12.7/agnostic/aarch64sbsa/nccl_2.12.7-1+cuda11.6_aarch64.txz",
                      "4520e4a99d3715edc3cfac849ce950d35e6ef18d9584b015c191e0ad7f132011")],
)
