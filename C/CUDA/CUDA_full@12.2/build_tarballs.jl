using BinaryBuilder

include("../../../fancy_toys.jl")

name = "CUDA_full"
version = v"12.2.1"

sources_linux = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda_12.2.1_535.86.10_linux.run",
               "c51e814eaa756160a73289b1f35880cc38c18e1ddedc87f46f7ff0d1696bdb95", "installer.run")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda_12.2.1_535.86.10_linux_ppc64le.run",
               "8f1aa60cc1e14fd7853eeecd53a78b7dfb2b2da0512a312cc35e4f5b79454f94", "installer.run")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda_12.2.1_535.86.10_linux_sbsa.run",
               "a9ae6bd02684c7acfb229484368bf2691d592767ce1aed10ae9aed92c81b9f09", "installer.run")
]
sources_win10 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda_12.2.1_536.67_windows.exe",
               "84b0fb6f92a5fa5d8d39de375832c8e9836be0221b6d424b4cf4fdff5352667a", "installer.exe")
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
                   cuda_nvrtc cuda_sanitizer_api cuda_profiler_api \
                   libcublas libcufft libcurand libcusolver libcusparse  \
                   libnpp libnvjpeg libnvjitlink; do
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
