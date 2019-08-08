using BinaryBuilder

name = "CUDA"
version = v"10.1.168"

sources = [
    "https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.168_418.67_rhel6.run" => 
    "ee395516e85185b47fac340d452d28e107dd18bf36e5af35e8f39ab2a9893f3b",
    "https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.168_mac.dmg" =>
    "a53d17c92b81bb8b8f812d0886a8c2ddf2730be6f5f2659aee11c0da207c2331",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/dmg2img-v1.6.7%2B0/dmg2img.v1.6.7.x86_64-linux-gnu.tar.gz" =>
    "2157b87982fa45e68f9413875ba41eb6193526c2d1cdf3e389500d888b18a01c",
]

script = raw"""
cd ${WORKSPACE}/srcdir

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
elif [[ ${target} == x86_64-apple-darwin* ]]; then
    dmg2img cuda_*_mac.dmg cuda_mac_converted.img
fi

# Clean up things we don't care about
rm -rf ${prefix}/NsightCompute*
rm -rf ${prefix}/nsightee*
rm -rf ${prefix}/doc
rm -rf ${prefix}/samples
rm -rf ${prefix}/libnvvp
rm -rf ${prefix}/libnsight
rm -rf ${prefix}/jre
"""

platforms = [
    Linux(:x86_64),
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
