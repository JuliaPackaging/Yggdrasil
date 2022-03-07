platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.1.32/11.3_06072021/cudnn-11.3-linux-x64-v8.2.1.32.tgz",
                      "39412acd9ef5dd27954b6b9f5df75bd381c5d7ceb7979af6c743a7f4521f9c77")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.1.32/11.3_06072021/cudnn-11.3-linux-ppc64le-v8.2.1.32.tgz",
                      "4ee4f2afeaae34fdb06da8d4942a6802aae94ecc51f307292c45966eecbe5fb9")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.1.32/11.3_06072021/cudnn-11.3-linux-aarch64sbsa-v8.2.1.32.tgz",
                      "e3a0e570cb8ba01d5d45e6eb1ebe29ff22fd5fb8ad45bfe7a448f4f95065ec1e")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.2.1.32/11.3_06072021/cudnn-11.3-windows-x64-v8.2.1.32.zip",
                      "5b9bf2dc4670fb1519ef55e13da5123f0b6b39fac5e6138e31388b269808d5f2")],
)
