using BinaryBuilder

include("../../../fancy_toys.jl")

name = "CUDA_full"
version = v"11.5.1"

sources_linux = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.5.1/local_installers/cuda_11.5.1_495.29.05_linux.run",
               "60bea2fc0fac95574015f865355afbf599422ec2c85554f5f052b292711a4bca", "installer.run")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.5.1/local_installers/cuda_11.5.1_495.29.05_linux_ppc64le.run",
               "9e0e494d945634fe8ad3e12d7b91806aa4220ed27487bb211030d651b27c67a9", "installer.run")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.5.1/local_installers/cuda_11.5.1_495.29.05_linux_sbsa.run",
               "73e1d0e97c7fa686efe7e00fb1e5f179372c4eec8e14d4f44ab58d5f6cf57f63", "installer.run")
]
sources_win10 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/11.5.1/local_installers/cuda_11.5.1_496.13_windows.exe",
               "538cda98841f8f9ba704682253562138c3d455fae49610c9625e0dff6b91807e", "installer.exe")
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

    for project in cuda_cudart cuda_cuobjdump cuda_cupti cuda_gdb \
                   cuda_nvcc cuda_nvdisasm cuda_nvml_dev cuda_nvprof cuda_nvprune \
                   cuda_nvrtc cuda_nvtx cuda_sanitizer_api cuda_thrust \
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

    for project in cuda_cudart cuda_cuobjdump cuda_cupti \
                   cuda_nvcc cuda_nvdisasm cuda_nvml_dev cuda_nvprof cuda_nvprune \
                   cuda_nvrtc cuda_nvtx cuda_sanitizer_api cuda_thrust \
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

# bump
