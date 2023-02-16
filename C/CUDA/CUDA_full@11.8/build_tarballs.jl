using BinaryBuilder

include("../../../fancy_toys.jl")

name = "CUDA_full"
version = v"11.8.0"

sources_linux = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run",
               "9223c4af3aebe4a7bbed9abd9b163b03a1b34b855fbc2b4a0d1b706ac09a5a16", "installer.run")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux_ppc64le.run",
               "f917fb7617033223938543ad3ae923190d99507acc08a399d752a2868e87349d", "installer.run")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux_sbsa.run",
               "e6e9a8d31163c9776b5e313fd7590877c5684e1ecddee741154f95704d4ed27c", "installer.run")
]
sources_win10 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_522.06_windows.exe",
               "b70f38f27321c0a53993438a91970a2e3c426f46da4c42eceff1eeea031a6555", "installer.exe")
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
                   cuda_nvcc cuda_nvdisasm cuda_nvml_dev cuda_nvprune \
                   cuda_nvrtc cuda_nvtx cuda_sanitizer_api cuda_profiler_api \
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
                   cuda_nvcc cuda_nvdisasm cuda_nvml_dev cuda_nvprune \
                   cuda_nvrtc cuda_nvtx cuda_sanitizer_api cuda_profiler_api \
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
