using BinaryBuilder

include("../../../fancy_toys.jl")

name = "CUDA_full"
version = v"9.0.176"

sources_linux = [
    FileSource("https://developer.nvidia.com/compute/cuda/9.0/Prod/local_installers/cuda_9.0.176_384.81_linux-run",
               "96863423feaa50b5c1c5e1b9ec537ef7ba77576a3986652351ae43e66bcd080c", "installer.run")
]
sources_macos = [
    FileSource("https://developer.nvidia.com/compute/cuda/9.0/Prod/local_installers/cuda_9.0.176_mac-dmg",
               "8fad950098337d2611d64617ca9f62c319d97c5e882b8368ed196e994bdaf225", "installer.dmg")
]
sources_windows = [
    FileSource("https://developer.nvidia.com/compute/cuda/9.0/Prod/local_installers/cuda_9.0.176_win10-exe",
               "615946c36c415d7d37b22dbade54469f0ed037b1b6470d6b8a108ab585e2621a", "installer.exe")
]

script = raw"""
cd ${WORKSPACE}/srcdir

# use a temporary directory to avoid running out of tmpfs in srcdir on Travis
temp=${WORKSPACE}/tmpdir
mkdir ${temp}

apk add p7zip

mkdir ${prefix}/cuda
if [[ ${target} == x86_64-linux-gnu ]]; then
    sh installer.run --tmpdir="${temp}" --extract="${temp}"
    cd ${temp}
    sh cuda-linux.*.run --noexec --keep
    cd pkg
    find .

    # clean-up
    rm -r libnsight libnvvp nsightee_plugins jre doc

    mv * ${prefix}/cuda
elif [[ ${target} == x86_64-apple-darwin* ]]; then
    7z x installer.dmg -o${temp}
    cd ${temp}
    tar -xzf CUDAMacOSXInstaller/CUDAMacOSXInstaller.app/Contents/Resources/payload/cuda_mac_installer_tk.tar.gz
    cd Developer/NVIDIA/CUDA-*/
    find .

    # clean-up
    rm -r libnsight libnvvp nsightee_plugins jre doc

    mv * ${prefix}/cuda
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    7z x installer.exe -o${temp}
    cd ${temp}
    find .

    mv EULA.txt ${prefix}/cuda

    for project in compiler curand cusparse npp cufft cublas cudart \
                   cusolver nvrtc nvgraph command_line_tools; do
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
