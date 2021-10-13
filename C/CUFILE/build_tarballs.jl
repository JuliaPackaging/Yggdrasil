using BinaryBuilder
using Base.BinaryPlatforms: arch, os

include("../../fancy_toys.jl")

name = "CUFILE"
version = v"1.0.2"
full_version = "1.0.2.10"

script = raw"""
mkdir -p ${libdir} ${prefix}/include

apk add dpkg
for deb in *.deb; do
    dpkg --extract $deb pkg
done
cd pkg
find .

cd usr/local/cuda*
install_license gds/EULA.txt

mv targets/*/include/* ${prefix}/include
mv targets/*/lib/* ${libdir}
rm ${libdir}/*.a
"""

products = [
    LibraryProduct("libcufile", :libcufile, dont_dlopen = true),
]

# XXX: CUDA_loader_jll's CUDA tag should match the library's CUDA version compatibility.
#      lacking that, we can't currently dlopen the library

dependencies = [Dependency(PackageSpec(name="CUDA_loader_jll"))]

cuda_versions = [v"11.4"]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    include("build_$(cuda_tag).jl")

    for (platform, sources) in platforms_and_sources
        augmented_platform = Platform(arch(platform), os(platform); cuda=cuda_tag)
        should_build_platform(triplet(augmented_platform)) || continue
        build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                       products, dependencies; lazy_artifacts=true)
        # NOTE: we skip audit because libcufile_rdma (which is unused)
        #       depends on the Mellanox infiniband driver (libmlx5.so)
    end
end
