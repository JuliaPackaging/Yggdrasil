using BinaryBuilder

include("../../../fancy_toys.jl")

name = "CUDA_full"
version = v"11.0.1"

sources_linux = [
    FileSource("http://developer.download.nvidia.com/compute/cuda/11.0.1/local_installers/cuda_11.0.1_450.36.06_linux.run",
               "f52a03afbc4b0fe982a74db252d36c965243b61e57bc84fbbba86318b4e26a0d", "installer.run")
]
sources_linux_sbsa = [
    # can we use this CUDA for development systems (e.g. Jetson) too?
    FileSource("http://developer.download.nvidia.com/compute/cuda/11.0.1/local_installers/cuda_11.0.1_450.36.06_linux_sbsa.run",
               "58c8840d91d93b1d9f08a11119e1f65cb2cb077fe3374531f480a85b4dd72bbd", "installer.run")
]
sources_linux_ppc64le = [
    FileSource("http://developer.download.nvidia.com/compute/cuda/11.0.1/local_installers/cuda_11.0.1_450.36.06_linux_ppc64le.run",
               "452ae400072136328efdf6d11947a84c126df28581ba6319df5871465bf2b318", "installer.run")
]
sources_win10 = [
    FileSource("http://developer.download.nvidia.com/compute/cuda/11.0.1/local_installers/cuda_11.0.1_451.22_win10.exe",
               "f93f4ecc29d9f24e95ec9899677118ce8007d143cc4ffdec9ac68d6a81757bfa", "installer.exe")
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
                   cuda_nvrtc cuda_nvtx cuda_sanitizer_api \
                   libcublas libcufft libcurand libcusolver libcusparse \
                   libnpp libnvjpeg; do
        [[ -d ${project} ]] || { echo "${project} does not exist!"; exit 1; }
        cp -a ${project}/* ${prefix}/cuda
    done

    cp -a integration/Sanitizer/* ${prefix}/cuda/bin
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    apk add p7zip

    7z x installer.exe -o${temp}
    cd ${temp}
    find .

    mv cuda_documentation/Doc/EULA.txt ${prefix}/cuda

    for project in cuda_cudart cuda_cuobjdump cuda_cupti cuda_memcheck \
                   cuda_nvcc cuda_nvdisasm cuda_nvml_dev cuda_nvprof cuda_nvprune \
                   cuda_nvrtc cuda_nvtx cuda_sanitizer_api \
                   libcublas libcufft libcurand libcusolver libcusparse  \
                   libnpp libnvjpeg; do
        [[ -d ${project} ]] || { echo "${project} does not exist!"; exit 1; }
        cp -a ${project}/*/* ${prefix}/cuda
    done

    # NVIDIA Tools Extension Library
    7z x "nsight_nvtx/nsight_nvtx/NVIDIA NVTX Installer.x86_64".*.msi -o${temp}/nvtx_installer
    find nvtx_installer
    for file in nvtx_installer/*.*_*; do
        mv $file $(echo $file | sed 's/\.\(\w*\)_.*/.\1/')
    done
    mv nvtx_installer/*.dll ${prefix}/cuda/bin
    mv nvtx_installer/*64_*.lib ${prefix}/cuda/lib/x64
    mv nvtx_installer/*32_*.lib ${prefix}/cuda/lib/Win32
    mv nvtx_installer/*.h ${prefix}/cuda/include

    # fixup
    chmod +x ${prefix}/cuda/bin/*.exe

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
                   [Linux(:x86_64)], products, dependencies;
                   skip_audit=true)
end

if should_build_platform("powerpc64le-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_ppc64le, script,
                   [Linux(:powerpc64le)], products, dependencies;
                   skip_audit=true)
end

if should_build_platform("x86_64-w64-mingw32")
    build_tarballs(ARGS, name, version, sources_win10, script,
                   [Windows(:x86_64)], products, dependencies;
                   skip_audit=true)
end
