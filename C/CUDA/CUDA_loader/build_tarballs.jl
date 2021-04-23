using BinaryBuilder, Pkg

name = "CUDA_loader"
version = v"0.1"

# NOTE: this only exports libraries that are used by CUDA.jl
products = [
    ExecutableProduct("nvdisasm", :nvdisasm),
    LibraryProduct(["libcufft", r"cufft64_.*"], :libcufft),
    LibraryProduct(["libcublas", r"cublas64_.*"], :libcublas),
    LibraryProduct(["libcusparse", r"cusparse64_.*"], :libcusparse),
    LibraryProduct(["libcusolver", r"cusolver64_.*"], :libcusolver),
    LibraryProduct(["libcurand", r"curand64_.*"], :libcurand),
    LibraryProduct(["libcupti", r"cupti64_.*"], :libcupti),
    LibraryProduct(["libnvToolsExt", "nvToolsExt64_1"], :libnvtoolsext),
    FileProduct(["lib/libcudadevrt.a", "lib/cudadevrt.lib"], :libcudadevrt),
    FileProduct("share/libdevice/libdevice.10.bc", :libdevice),
    # only on CUDA 10.2 or higher
    LibraryProduct(["libcusolverMg", r"cusolverMg64_.*"], :libcusolverMg; optional=true),
    # only on CUDA 11.0 or higher
    ExecutableProduct("compute-sanitizer", :compute_sanitizer; optional=true),
]

cuda_versions = [v"9.0", v"9.2", v"10.0", v"10.2", v"11.0", v"11.1", v"11.2", v"11.3"]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    include("build_$(cuda_tag).jl")

    for platform in platforms
        platform.tags["cuda"] = cuda_tag
    end

    build_tarballs(ARGS, name, version, [], script, platforms, products, dependencies;
                   lazy_artifacts=true)
end
