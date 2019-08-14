using BinaryBuilder

name = "CUDA"
version = v"10.1.168"

sources = [
    "https://developer.nvidia.com/compute/cuda/10.1/Prod/cluster_management/cuda_cluster_pkgs_10.1.168_418.67_rhel6.tar.gz" => 
    "965570c92de387cec04d77a2bdce26b6457b027c0b2b12dc537a5ca1c1aa82b3",
    "https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.168_mac.dmg" =>
    "a53d17c92b81bb8b8f812d0886a8c2ddf2730be6f5f2659aee11c0da207c2331",
    "https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.168_425.25_win10.exe" =>
    "52450b81a699cb75086e9d3d62abb2a33f823fcf5395444e57ebb5864cc2fd51",
]

script = raw"""
cd ${WORKSPACE}/srcdir

apk add p7zip rpm

# Make temporary space for extraction
mkdir -p $(pwd)/.tmp

if [[ ${target} == x86_64-linux-gnu ]]; then
    cd cuda_cluster_pkgs*

    # extract cluster packages
    rpm2cpio cuda-cluster-devel*.rpm | cpio -idmv
    rpm2cpio cuda-cluster-runtime*.rpm | cpio -idmv

    # Install things we like
    for subdir in bin lib64 include extras nvvm nvml targets; do
        mkdir -p ${prefix}/${subdir}
        mv usr/local/cuda*/${subdir}/* ${prefix}/${subdir}/
    done

    # We need to maintain the "targets" directories
    for dir in include lib; do
        rm -rf ${prefix}/targets/x86_64-linux/${dir}
        ln -s ../../${dir} ${prefix}/targets/x86_64-linux/${dir}
    done
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    cd .tmp
    7z x ${WORKSPACE}/srcdir/cuda_*_win10.exe

    # Install things
    mkdir -p ${prefix}/bin ${prefix}/include ${prefix}/lib/x64
    for project in curand cusparse npp cufft cublas cudart cusolver nvrtc; do
        mv ${project}/bin/* ${prefix}/bin/
        [[ -d ${project}_dev/include ]] && mv ${project}_dev/include/* ${prefix}/include/
        [[ -d ${project}_dev/lib ]] && mv ${project}_dev/lib/x64/* ${prefix}/lib/x64/
    done
elif [[ ${target} == x86_64-apple-darwin* ]]; then
    cd .tmp
    7z x ${WORKSPACE}/srcdir/cuda_*_mac.dmg
    7z x 5.hfs

    # Extract embedded tarball into prefix
    tar -C ${prefix} -zxvf CUDAMacOSXInstaller/CUDAMacOSXInstaller.app/Contents/Resources/payload/cuda_mac_installer_tk.tar.gz

    # Clean up things we don't care about
    rm -rf ${prefix}/usr

    for subdir in bin lib include extras nvvm; do
        mv ${prefix}/Developer/NVIDIA/CUDA-*/${subdir} ${prefix}/
    done
    rm -rf ${prefix}/Developer
fi
"""

platforms = [
    Linux(:x86_64),
    Windows(:x86_64),
    MacOS(:x86_64),
]

products(prefix) = [
    ExecutableProduct(prefix, "nvcc", :nvcc),
    ExecutableProduct(prefix, "cudafe++", :cudafepp),
    ExecutableProduct(prefix, "nvprof", :nvprof),
    ExecutableProduct(prefix, "ptxas", :ptxas),
    LibraryProduct(prefix, "libcudart", :libcudart),
    LibraryProduct(prefix, "libcufft", :libcufft),
    LibraryProduct(prefix, "libcufftw", :libcufftw),
    LibraryProduct(prefix, "libcurand", :libcurand),
    LibraryProduct(prefix, "libcublas", :libcublas),
    LibraryProduct(prefix, "libcusolver", :libcusolver),
    LibraryProduct(prefix, "libcusparse", :libcusparse),
    LibraryProduct(prefix, "libnvrtc", :libnvrtc),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)
