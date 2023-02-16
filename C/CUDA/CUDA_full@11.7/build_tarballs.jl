using BinaryBuilder

include("../../../fancy_toys.jl")

name = "CUDA_full"
version = v"11.7.1"

sources_linux = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_515.65.01_linux.run",
               "52286a29706549b7d0feeb0e7e3eca1b15287c436a69fa880ad385b1be3e04db", "installer.run")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_515.65.01_linux_ppc64le.run",
               "f59fc381cbd903da55bfea9f81534bd4d20e3db716c332be3d2c4804efc2ec6b", "installer.run")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_515.65.01_linux_sbsa.run",
               "1607b98c30cb8efa52b9c8f564ec92d26ee1922cb677740aafacce313e544ecd", "installer.run")
]
sources_win10 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_516.94_windows.exe",
               "22d6899b2d8851e7db54bdea201b280c544d0c1867da0128a659e2a223bc36c2", "installer.exe")
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

    for project in cuda_cccl cuda_cudart cuda_cuobjdump cuda_cupti cuda_gdb \
                   cuda_nvcc cuda_nvdisasm cuda_nvml_dev cuda_nvprof cuda_nvprune \
                   cuda_nvrtc cuda_nvtx cuda_sanitizer_api \
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

    for project in cuda_cccl cuda_cudart cuda_cuobjdump cuda_cupti \
                   cuda_nvcc cuda_nvdisasm cuda_nvml_dev cuda_nvprof cuda_nvprune \
                   cuda_nvrtc cuda_nvtx cuda_sanitizer_api \
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

if should_build_platform("aarch64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_aarch64, script,
                   [Platform("aarch64", "linux")], products, dependencies;
                   skip_audit=true)
end

if should_build_platform("x86_64-w64-mingw32")
    build_tarballs(ARGS, name, version, sources_win10, script,
                   [Platform("x86_64", "windows")], products, dependencies;
                   skip_audit=true)
end
