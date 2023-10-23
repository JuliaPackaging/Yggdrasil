platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/x64/nccl_$(version)-1+12.0_x86_64.txz",
                      "36fff137153ef73e6ee10bfb07f4381240a86fb9fb78ce372414b528cbab2293")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/ppc64le/nccl_$(version)-1+cuda12.0_ppc64le.txz",
                      "32fc6734ed3306b5ad956f503704d186cfcdd8ca21cb0466f9fe5c512f9c799c")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/aarch64sbsa/nccl_$(version)-1+cuda12.0_aarch64.txz",
                      "aa7b11bbbadb011b155b447dabcc8ee1b521f1ff34a39ef27e766ebe36f28c05")],
)
