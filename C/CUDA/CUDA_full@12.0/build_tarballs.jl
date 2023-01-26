using BinaryBuilder

include("../../../fancy_toys.jl")

name = "CUDA_full"
version = v"12.0.0"

sources_linux = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda_12.0.0_525.60.13_linux.run",
               "905e9b9516900839fb76064719db752439f38b8cb730b49335d8bd53ddfad392", "installer.run")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda_12.0.0_525.60.13_linux_ppc64le.run",
               "117fe045c71668e45d41c6119b6f27875370c78e33fc56795b6fe014c796ec60", "installer.run")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda_12.0.0_525.60.13_linux_sbsa.run",
               "cd13e9c65d4c8f895a968706f46064d536be09f9706bce081cc864b7e4fa4544", "installer.run")
]
sources_win10 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda_12.0.0_527.41_windows.exe",
               "16d018a96f88b19a491787370c9c125494c4ecfbd863e09403363b3379fc323c", "installer.exe")
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
                   cuda_nvrtc cuda_sanitizer_api cuda_profiler_api \
                   libcublas libcufft libcurand libcusolver libcusparse \
                   libnpp libnvjpeg libnvjitlink; do
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
                   cuda_nvcc cuda_nvdisasm cuda_nvml_dev cuda_nvprune \
                   cuda_nvrtc cuda_sanitizer_api cuda_profiler_api \
                   libcublas libcufft libcurand libcusolver libcusparse  \
                   libnpp libnvjpeg libnvjitlink; do
        [[ -d ${project} ]] || { echo "${project} does not exist!"; exit 1; }
        cp -a ${project}/*/* ${prefix}/cuda
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
