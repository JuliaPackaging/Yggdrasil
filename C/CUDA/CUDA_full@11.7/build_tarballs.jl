using BinaryBuilder

include("../../../fancy_toys.jl")

name = "CUDA_full"
version = v"11.7.0"

sources_linux = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda_11.7.0_515.43.04_linux.run",
               "087fdfcbba1f79543b1f78e43a8dfdac5f6db242d042dde820e16dc185892f26", "installer.run")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda_11.7.0_515.43.04_linux_ppc64le.run",
               "74a507ac54067c258e6b7c9063c98d411116ecc5c5397b1f6e6a999e86dff08a", "installer.run")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda_11.7.0_515.43.04_linux_sbsa.run",
               "e777839a618ca9a3d5ad42ded43a1b6392af2321a7327635a4afcc986876a21b", "installer.run")
]
sources_win10 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda_11.7.0_516.01_windows.exe",
               "ec0f554ead2cee1fb51d8bf98c7d13c5df91df62d4654e4ea626fb4278c4a4b6", "installer.exe")
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

    # HACK: remove static libraries to get past GitHub's 2GB limit
    rm ${prefix}/cuda/lib64/*_static.a
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
