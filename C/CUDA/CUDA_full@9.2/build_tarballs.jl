using BinaryBuilder

include("../../../fancy_toys.jl")

name = "CUDA_full"
version = v"9.2.148"

sources_linux = [
    FileSource("https://developer.nvidia.com/compute/cuda/9.2/Prod2/local_installers/cuda_9.2.148_396.37_linux",
               "f5454ec2cfdf6e02979ed2b1ebc18480d5dded2ef2279e9ce68a505056da8611", "installer.run")
]
sources_macos = [
    FileSource("https://developer.nvidia.com/compute/cuda/9.2/Prod2/local_installers/cuda_9.2.148_mac",
               "defb095aa002301f01b2f41312c9b1630328847800baa1772fe2bbb811d5fa9f", "installer.dmg")
]
sources_windows = [
    FileSource("https://developer.nvidia.com/compute/cuda/9.2/Prod2/local_installers2/cuda_9.2.148_win10",
               "7d99a6d135587d029c2cf159ade4e71c02fc1a922a5ffd06238b2bde8bedc362", "installer.exe")
]

script = raw"""
cd ${WORKSPACE}/srcdir

# use a temporary directory to avoid running out of tmpfs in srcdir on Travis
temp=${WORKSPACE}/tmpdir
mkdir ${temp}

apk add p7zip

if [[ ${target} == x86_64-linux-gnu ]]; then
    sh installer.run --tmpdir="${temp}" --extract="${temp}"
    cd ${temp}
    sh cuda-linux.*.run --noexec --keep
    cd pkg
    find .

    # clean-up
    rm -r libnsight libnvvp nsightee_plugins jre doc

    mv * ${prefix}
    cd ${prefix}

    install_license EULA.txt
elif [[ ${target} == x86_64-apple-darwin* ]]; then
    7z x installer.dmg -o${temp}
    cd ${temp}
    tar -xzf CUDAMacOSXInstaller/CUDAMacOSXInstaller.app/Contents/Resources/payload/cuda_mac_installer_tk.tar.gz
    cd Developer/NVIDIA/CUDA-*/
    find .

    # clean-up
    rm -r libnsight libnvvp nsightee_plugins jre doc

    mv * ${prefix}
    cd ${prefix}

    install_license EULA.txt
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    7z x installer.exe -o${temp}
    cd ${temp}
    find .

    for project in cuobjdump memcheck nvcc cupti nvdisasm curand cusparse npp cufft \
                   cublas cudart cusolver nvrtc nvgraph nvprof nvprune; do
        [[ -d ${project} ]] || { echo "${project} does not exist!"; exit 1; }
        cp -a ${project}/* ${prefix}
    done

    # NVIDIA Tools Extension Library
    7z x "CUDAVisualStudioIntegration/NVIDIA NVTX Installer.x86_64".*.msi -o${temp}/nvtx_installer
    find nvtx_installer
    for file in nvtx_installer/*.*_*; do
        mv $file $(echo $file | sed 's/\.\(\w*\)_.*/.\1/')
    done
    mv nvtx_installer/*.dll ${prefix}/bin
    mv nvtx_installer/*64_*.lib ${prefix}/lib/x64
    mv nvtx_installer/*32_*.lib ${prefix}/lib/Win32
    mv nvtx_installer/*.h ${prefix}/include
    find .

    install_license EULA.txt

    # fixup
    chmod +x ${prefix}/bin/*.exe

    # clean-up
    rm ${prefix}/*.nvi
fi
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

if should_build_platform("x86_64-apple-darwin14")
    build_tarballs(non_reg_ARGS, name, version, sources_macos, script,
                   [MacOS(:x86_64)], products, dependencies;
                   skip_audit=true)
end

if should_build_platform("x86_64-w64-mingw32")
    build_tarballs(ARGS, name, version, sources_windows, script,
                   [Windows(:x86_64)], products, dependencies;
                   skip_audit=true)
end
