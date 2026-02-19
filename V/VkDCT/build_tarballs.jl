using BinaryBuilder

# The version of this JLL
name = "VkDCT"
version = v"1.3.4"

# Sources - VkFFT release and bundled shim/patches
sources = [
    GitSource("https://github.com/DTolm/VkFFT.git",
              "066a17c17068c0f11c9298d848c2976c71fad1c1"),
    DirectorySource("./bundled"),
]

# The script to build the binary
script = raw"""
cd ${WORKSPACE}/srcdir

# Apply patches
atomic_patch -p1 -d VkFFT patches/fix_log2_ambiguity.patch

# Enter the inner directory where headers are located
cd VkFFT/vkFFT

# Copy the bundled shim source
cp ${WORKSPACE}/srcdir/dct_shim.cu .

# Locate nvcc - properly add to PATH
# CUDA_full_jll installation location can vary in the sandbox
NVCC=$(find / -type f -name nvcc -executable 2>/dev/null | head -n 1)
if [ -z "$NVCC" ]; then
    echo "nvcc not found in sandbox"
    exit 1
fi
# Add to PATH so nvcc can find its own subprocesses (cic, ptxas)
export PATH="$(dirname $NVCC):$PATH"
echo "Found and added nvcc: $NVCC"

mkdir -p ${libdir}

nvcc -O3 -std=c++11 --shared -cudart shared -Xcompiler -fPIC -arch=sm_60 -o ${libdir}/libvkfft_dct.so dct_shim.cu -I. -lcuda -lnvrtc

install_license ../LICENSE
"""

# Platforms - restricting to Linux/x86_64 for now as requested by typical GPU setups
platforms = [
    Platform("x86_64", "linux"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libvkfft_dct", :libvkfft_dct)
]

dependencies = [
    # Build-time: Need nvcc
    BuildDependency("CUDA_full_jll"),
    
    # Runtime: Need libraries matching CUDA.jl's stack
    Dependency("CUDA_Runtime_jll"),   # libcudart
    Dependency("CUDA_Driver_jll"),    # libcuda (stub/loader)
    Dependency("CUDA_Compiler_jll"),  # libnvrtc
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10")
