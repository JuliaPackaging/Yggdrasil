using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../../fancy_toys.jl")

name = "TensorRT"
version = v"8.2.3"

script = raw"""
cd ${WORKSPACE}/srcdir

mkdir -p ${bindir} ${libdir} ${includedir}
cd TensorRT*
mv bin/* ${bindir}
mv include/* ${includedir}
mv lib/*.${dlext}* ${libdir}
if [[ ${target} == x86_64-w64-mingw32 ]]; then
    chmod +x ${bindir}/*.{dll,exe}
    install_license doc/TensorRT-SLA.pdf 
else
    install_license doc/pdf/TensorRT-SLA.pdf 
fi
"""

lib_names = [
    "nvinfer",
    "nvinfer_plugin",
    "nvonnxparser",
    "nvparsers"
]

products = vcat(
    [LibraryProduct(["lib" * lib_name, lib_name], Symbol("lib" * lib_name)) for lib_name in lib_names],
    [ExecutableProduct("trtexec", :trtexec)]
)

cuda_versions = [v"10.2", v"11.0", v"11.1", v"11.2", v"11.3", v"11.4", v"11.5"]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    include("build_$(cuda_tag).jl")
    cudnn_build_version = cuda_version < v"11.4" ? v"8.2.1" : cuda_version < v"11.5" ? v"8.2.2" : v"8.3.1"
    dependencies = [Dependency("CUDNN_jll", cudnn_build_version; compat="8.2")]
    for (platform, sources) in platforms_and_sources
        augmented_platform = Platform(arch(platform), os(platform); cuda=cuda_tag)
        should_build_platform(triplet(augmented_platform)) || continue
        build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                       products, dependencies; lazy_artifacts=true)
    end
end
