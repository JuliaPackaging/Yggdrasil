using BinaryBuilder

include("../../../fancy_toys.jl")

name = "CUDA_full"
version = v"10.1.243"

sources_linux = [
    FileSource("http://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.243_418.87.00_linux.run",
               "e7c22dc21278eb1b82f34a60ad7640b41ad3943d929bebda3008b72536855d31", "installer.run")
]
sources_macos = [
    FileSource("http://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.243_mac.dmg",
               "432a2f07a793f21320edc5d10e7f68a8e4e89465c31e1696290bdb0ca7c8c997", "installer.dmg")
]
sources_windows = [
    FileSource("http://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.243_426.00_win10.exe",
               "35d3c99c58dd601b2a2caa28f44d828cae1eaf8beb70702732585fa001cd8ad7", "installer.exe")
]

script = raw"""
cd ${WORKSPACE}/srcdir

# use a temporary directory to avoid running out of tmpfs in srcdir on Travis
temp=${WORKSPACE}/tmpdir
mkdir ${temp}

apk add p7zip

mkdir ${prefix}/cuda
if [[ ${target} == x86_64-linux-gnu ]]; then
    sh installer.run --tmpdir="${temp}" --target "${temp}" --noexec
    cd ${temp}/builds/cuda-toolkit
    find .

    # clean-up
    rm -r libnsight libnvvp nsightee_plugins nsight-compute-2019.4.0 nsight-systems-2019.3.7.5 doc

    mv * ${prefix}/cuda
elif [[ ${target} == x86_64-apple-darwin* ]]; then
    7z x installer.dmg 5.hfs -o${temp}
    cd ${temp}
    7z x 5.hfs
    tar -zxf CUDAMacOSXInstaller/CUDAMacOSXInstaller.app/Contents/Resources/payload/cuda_mac_installer_tk.tar.gz
    cd Developer/NVIDIA/CUDA-*/
    find .

    # clean-up
    rm -r libnsight libnvvp nsightee_plugins nsight-compute-2019.4.0 NsightSystems-2019.3.7.5 doc

    mv * ${prefix}/cuda
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    7z x installer.exe -o${temp}
    cd ${temp}
    find .

    mv EULA.txt ${prefix}/cuda

    for project in cuobjdump memcheck nvcc cupti nvdisasm curand cusparse npp cufft \
                   cublas cudart cusolver nvrtc nvgraph nvprof nvprune; do
        [[ -d ${project} ]] || { echo "${project} does not exist!"; exit 1; }
        cp -a ${project}/* ${prefix}/cuda
    done

    # NVIDIA Tools Extension Library
    7z x "CUDAVisualStudioIntegration/NVIDIA NVTX Installer.x86_64".*.msi -o${temp}/nvtx_installer
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

if should_build_platform("x86_64-apple-darwin14")
    build_tarballs(non_reg_ARGS, name, version, sources_macos, script,
                   [Platform("x86_64", "macos")], products, dependencies;
                   skip_audit=true)
end

if should_build_platform("x86_64-w64-mingw32")
    build_tarballs(ARGS, name, version, sources_windows, script,
                   [Platform("x86_64", "windows")], products, dependencies;
                   skip_audit=true)
end
