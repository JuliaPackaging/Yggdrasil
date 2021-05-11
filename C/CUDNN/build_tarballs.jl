using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../../fancy_toys.jl")

name = "CUDNN"
version = v"8.2.0"#.53

script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir
if [[ ${target} == x86_64-linux-gnu ]]; then
    cd cuda
    find .

    install_license NVIDIA_SLA_cuDNN_Support.txt

    mv lib64/libcudnn*.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == powerpc64le-linux-gnu ]]; then
    cd cuda/targets/ppc64le-linux
    find .

    install_license NVIDIA_SLA_cuDNN_Support.txt

    mv lib/libcudnn*.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    cd cuda
    find .

    install_license NVIDIA_SLA_cuDNN_Support.txt

    mv bin/cudnn*64_*.dll ${libdir}
    mv include/* ${prefix}/include

    # fixup
    chmod +x ${libdir}/*.{exe,dll}
fi
"""

products = [
    LibraryProduct(["libcudnn", "cudnn64_$(version.major)"], :libcudnn, dont_dlopen = true),
]

# XXX: CUDA_loader_jll's CUDA tag should match the library's CUDA version compatibility.
#      lacking that, we can't currently dlopen the library

dependencies = [Dependency(PackageSpec(name="CUDA_loader_jll"))]

cuda_versions = [v"10.2", v"11.0", v"11.1", v"11.2", v"11.3"]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    include("build_$(cuda_tag).jl")

    for (platform, sources) in platforms_and_sources
        augmented_platform = Platform(arch(platform), os(platform); cuda=cuda_tag)
        should_build_platform(triplet(augmented_platform)) || continue
        build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                       products, dependencies; lazy_artifacts=true)
    end
end
