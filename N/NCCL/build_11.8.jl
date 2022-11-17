platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/x64/nccl_$(version)-1+cuda11.8_x86_64.txz",
                      "c819d7fa1f476812f87df80ca612df1920702cd6347bfbfd73a151eaced439e9")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/ppc64le/nccl_$(version)-1+cuda11.8_ppc64le.txz",
                      "db405916e24b274f90da52fb91b6c60b795d09ba9e41d021ecf678b422eef09c")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/machine-learning/nccl/secure/$(version)/agnostic/aarch64sbsa/nccl_$(version)-1+cuda11.8_aarch64.txz",
                      "2dd62289f045fda4ffbbc3c4cb3a54c6b95673ab0d48bb472b72ca1335527b7e")],
)
