include("../../fancy_toys.jl")

version = v"7.6.5"

name = "CUDNN_CUDA$(cuda_version.major).$(cuda_version.minor)"

script = raw"""
cd ${WORKSPACE}/srcdir
if [[ ${target} == x86_64-linux-gnu ]]; then
    cd cuda
    find .

    install_license NVIDIA_SLA_cuDNN_Support.txt

    mv lib64/libcudnn.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    cd cuda
    find .

    install_license NVIDIA_SLA_cuDNN_Support.txt

    mv bin/cudnn64_*.dll ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == x86_64-apple-darwin* ]]; then
    cd cuda
    find .

    install_license NVIDIA_SLA_cuDNN_Support.txt

    mv lib/libcudnn.*dylib ${libdir}
    mv include/* ${prefix}/include
fi
"""

products = [
    LibraryProduct(["libcudnn", "cudnn64_$(version.major)"], :libcudnn),
]

dependencies = [Dependency(PackageSpec(name="CUDA_jll", version=cuda_version))]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

if @isdefined(sources_linux) && should_build_platform("x86_64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux, script,
                   [Linux(:x86_64)], products, dependencies)
end

if @isdefined(sources_windows) && should_build_platform("x86_64-w64-mingw32")
    build_tarballs(ARGS, name, version, sources_windows, script,
                   [Windows(:x86_64)], products, dependencies)
end

if @isdefined(sources_macos) && should_build_platform("x86_64-apple-darwin14")
    build_tarballs(ARGS, name, version, sources_macos, script,
                   [MacOS(:x86_64)], products, dependencies)
end
