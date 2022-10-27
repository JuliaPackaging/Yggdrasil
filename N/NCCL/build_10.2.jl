platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/x64/nccl_$(version)-$(build)+cuda10.2_x86_64.txz",
                      "32cc36aa908978a00f74f4e7a829e4bc8d27bb2a46ac43bed9e81f31dd784cde")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/ppc64le/nccl_$(version)-$(build)+cuda10.2_ppc64le.txz",
                      "d7fac7c40275f368088b8edd97efd0b47e783a4c2f26a1c3f4b34c5680259330")],
)
