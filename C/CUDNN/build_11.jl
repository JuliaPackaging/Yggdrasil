platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.6.0/local_installers/11.8/cudnn-linux-x86_64-8.6.0.163_cuda11-archive.tar.xz",
                      "bbc396df47294c657edc09c600674d608cb1bfc80b82dcf4547060c21711159e")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.6.0/local_installers/11.8/cudnn-linux-ppc64le-8.6.0.163_cuda11-archive.tar.xz",
                      "c8a25e7e3df1bb9c4e18a4f24dd5f25cfd4bbe8b7054e34008e53b2be4f58a80")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.6.0/local_installers/11.8/cudnn-linux-sbsa-8.6.0.163_cuda11-archive.tar.xz",
                      "a0202278d3cbd4f3adc3f7816bff6071621cb042b0903698b477acac8928ac06")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/cudnn/secure/8.6.0/local_installers/11.8/cudnn-windows-x86_64-8.6.0.163_cuda11-archive.zip",
                      "78b4e5c455c4e8303b5d6c5401916fb0d731ea5da72b040cfa81e0a340040ae3")],
)
