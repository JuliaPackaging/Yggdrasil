using BinaryBuilder

include("../../../fancy_toys.jl")

name = "CUDA_full"
version = v"11.3.1"

sources_linux = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.3.1/local_installers/cuda_11.3.1_465.19.01_linux.run",
               "ad93ea98efced35855c58d3a0fc326377c60917cb3e8c017d3e6d88819bf2934", "installer.run")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.3.1/local_installers/cuda_11.3.1_465.19.01_linux_ppc64le.run",
               "220f2c10a21500d62b03c6848c1659ebb3a8e10dc0915ab87b86b397058407c5", "installer.run")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.3.1/local_installers/cuda_11.3.1_465.19.01_linux_sbsa.run",
               "39990d3da88b21289ac20850bc183f0b66275f32e1f562b551c05843bf506e4c", "installer.run")
]
sources_win10 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.3.1/local_installers/cuda_11.3.1_465.89_win10.exe",
               "ff5beed6004e968dd413200535168559e90d7d870e8cf7189786cd32cd78cf01", "installer.exe")
]

script = raw"""
cd ${WORKSPACE}/srcdir

# use a temporary directory to avoid running out of tmpfs
temp=${WORKSPACE}/tmpdir
mkdir ${temp}

mkdir ${prefix}/cuda
if [[ ${target} == *-linux-gnu ]]; then
    # don't run the embedded installer (libc issue, doesn't work on ppc),
    # but instruct makeself to uncompress the embedded archive.
    sh installer.run --noexec --target "${temp}"
    cd ${temp}/builds
    find .

    cp cuda_documentation/EULA.txt ${prefix}/cuda

    for project in cuda_cudart cuda_cuobjdump cuda_cupti cuda_gdb cuda_memcheck \
                   cuda_nvcc cuda_nvdisasm cuda_nvml_dev cuda_nvprof cuda_nvprune \
                   cuda_nvrtc cuda_nvtx cuda_sanitizer_api cuda_thrust \
                   libcublas libcufft libcurand libcusolver libcusparse \
                   libnpp libnvjpeg; do
        [[ -d ${project} ]] || { echo "${project} does not exist!"; exit 1; }
        cp -a ${project}/* ${prefix}/cuda
    done

    cp -a integration/Sanitizer/* ${prefix}/cuda/bin

    # HACK: remove most static libraries to get past GitHub's 2GB limit
    for lib in ${prefix}/cuda/lib64/*.a; do
        [[ ${lib} == *libcudadevrt.a ]] && continue
        [[ ${lib} == *libnvptxcompiler_static.a ]] && continue
        [[ ${lib} == *libcudart_static.a ]] && continue
        rm ${lib}
    done
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    apk add p7zip

    7z x installer.exe -o${temp}
    cd ${temp}
    find .

    mv cuda_documentation/Doc/EULA.txt ${prefix}/cuda

    for project in cuda_cudart cuda_cuobjdump cuda_cupti cuda_memcheck \
                   cuda_nvcc cuda_nvdisasm cuda_nvml_dev cuda_nvprof cuda_nvprune \
                   cuda_nvrtc cuda_nvtx cuda_sanitizer_api cuda_thrust \
                   libcublas libcufft libcurand libcusolver libcusparse  \
                   libnpp libnvjpeg; do
        [[ -d ${project} ]] || { echo "${project} does not exist!"; exit 1; }
        cp -a ${project}/*/* ${prefix}/cuda
    done

    # HACK: remove most static libraries to get past GitHub's 2GB limit
    for lib in ${prefix}/cuda/lib/x64/*.lib; do
        [[ ${lib} == *cudadevrt.lib ]] && continue
        [[ ${lib} == *nvptxcompiler_static.lib ]] && continue
        [[ ${lib} == *cudart_static.lib ]] && continue
        rm ${lib}
    done

    # fixup
    chmod +x ${prefix}/cuda/bin/*.{exe,dll}

    # clean-up
    rm ${prefix}/cuda/*.nvi
fi

rm -rf ${temp}

cd ${prefix}/cuda
install_license EULA.txt
"""

products = Product[
    # this JLL isn't meant for use by Julia packages, but only as build dependency
]

dependencies = []

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

if should_build_platform("x86_64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux, script,
                   [Platform("x86_64", "linux")], products, dependencies;
                   skip_audit=true)
end

if should_build_platform("powerpc64le-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_ppc64le, script,
                   [Platform("powerpc64le", "linux")], products, dependencies;
                   skip_audit=true)
end

if should_build_platform("x86_64-w64-mingw32")
    build_tarballs(ARGS, name, version, sources_win10, script,
                   [Platform("x86_64", "windows")], products, dependencies;
                   skip_audit=true)
end

