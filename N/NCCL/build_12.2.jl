platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/x64/nccl_$(version)-1+12.2_x86_64.txz",
                      "36fff137153ef73e6ee10bfb07f4381240a86fb9fb78ce372414b528cbab2293")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/ppc64le/nccl_$(version)-1+cuda12.2_ppc64le.txz",
                      "c5584c80f0744897e602237947fb31fada2741ec34c872b61ad36f96606b47db")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/aarch64sbsa/nccl_$(version)-1+cuda12.2_aarch64.txz",
                      "452d6a9511c4b4fe5ceb537f31d53b4f5c95608c743116d493119dfe83307ed2")],
)
