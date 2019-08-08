using BinaryBuilder

name = "CUDA"
version = v"10.1.168"

sources = [
    "https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.168_418.67_rhel6.run" => 
    "ee395516e85185b47fac340d452d28e107dd18bf36e5af35e8f39ab2a9893f3b",
    "https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.168_mac.dmg" =>
    "a53d17c92b81bb8b8f812d0886a8c2ddf2730be6f5f2659aee11c0da207c2331",
    "https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.168_425.25_win10.exe" =>
    "52450b81a699cb75086e9d3d62abb2a33f823fcf5395444e57ebb5864cc2fd51",
]

script = raw"""
cd ${WORKSPACE}/srcdir

apk add p7zip

# Make temporary space for extraction
mkdir -p $(pwd)/.tmp

if [[ ${target} == x86_64-linux-gnu ]]; then
    chmod +x cuda_*_rhel6.run
    ./cuda_*_rhel6.run \
        --silent \
        --toolkit \
        --toolkitpath=${prefix} \
        --no-man-page \
        --tmpdir=$(pwd)/.tmp \
        --no-drm
    
    # Clean up things we don't care about
    rm -rf ${prefix}/NsightCompute*
    rm -rf ${prefix}/nsightee*
    rm -rf ${prefix}/doc
    rm -rf ${prefix}/samples
    rm -rf ${prefix}/libnvvp
    rm -rf ${prefix}/libnsight
    rm -rf ${prefix}/jre
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    cd .tmp
    7z x ${WORKSPACE}/srcdir/cuda_*_win10.exe

    # Install things
    mkdir -p ${prefix}/bin
    for project in curand cusparse npp cufft cublas cudart cusolver nvrtc; do
        mv ${project}/bin/* ${prefix}/bin
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
    LibraryProduct(prefix, "libcusolver", :libcusolver),
    LibraryProduct(prefix, "libcusparse", :libcusparse),
    LibraryProduct(prefix, "libnvrtc", :libnvrtc),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)
