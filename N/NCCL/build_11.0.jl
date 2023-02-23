platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/x64/nccl_$(version)-$(build)+cuda11.0_x86_64.txz",
                      "6b8174b1a6ca90f1e0b615df855e27321f02927301fd94aea5d0999e71d7b896")],
)
