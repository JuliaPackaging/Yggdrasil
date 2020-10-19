include("../../fancy_toys.jl")

version = v"8.0.3"#.33

name = "CUDNN_CUDA$(cuda_version.major)$(cuda_version.minor)"

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
fi
"""

products = [
    LibraryProduct(["libcudnn", "cudnn64_$(version.major)"], :libcudnn),
]

dependencies = [Dependency(PackageSpec(name="CUDA_jll", version=cuda_version))]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

if @isdefined(sources_linux_x64) && should_build_platform("x86_64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_x64, script,
                   [Platform("x86_64", "linux")], products, dependencies)
end

if @isdefined(sources_linux_ppc64le) && should_build_platform("powerpc64le-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_ppc64le, script,
                   [Platform("powerpc64le", "linux")], products, dependencies)
end

if @isdefined(sources_windows) && should_build_platform("x86_64-w64-mingw32")
    build_tarballs(ARGS, name, version, sources_windows, script,
                   [Platform("x86_64", "windows")], products, dependencies)
end
