platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.0.1/tars/TensorRT-8.0.1.6.Linux.x86_64-gnu.cuda-11.3.cudnn8.2.tar.gz",
                      "def6a5ee50bed25a68a9c9e22ec671a8f29ee5414bde47c5767bd279e5596f88")],
    Platform("ppc64le", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.0.1/tars/TensorRT-8.0.1.6.CentOS-8.3.ppc64le-gnu.cuda-11.3.cudnn8.2.tar.gz",
                      "fd33a32085c468f638505e2603936fa4e3f2a3fa46989570fa0b9e31a9e6914a")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.0.1/tars/TensorRT-8.0.1.6.Ubuntu-20.04.aarch64-gnu.cuda-11.3.cudnn8.2.tar.gz",
                      "ea322da72b1b1ca6b8d0715ab14668c54f7d00ad22695d41a85a7055df9f63e1")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.nvidia.com/compute/machine-learning/tensorrt/secure/8.0.1/zip/TensorRT-8.0.1.6.Windows10.x86_64.cuda-11.3.cudnn8.2.zip",
                      "e51b382e931ae9032e431fff218cd2cf2d2b7a7c66c7a6bdf453557612466ae1")],
)
