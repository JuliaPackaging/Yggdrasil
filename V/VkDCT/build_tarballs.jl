using BinaryBuilder

# The version of this JLL
name = "VkDCT"
version = v"0.1.0"

# Sources - VkFFT release and inline shim
sources = [
    GitSource("https://github.com/DTolm/VkFFT.git",
              "066a17c17068c0f11c9298d848c2976c71fad1c1"),
]

# The script to build the binary
script = raw"""
cd VkFFT*

# Create the shim file (inlined from repo)
cat << 'EOF' > dct_shim.cu
// dct_shim.cu
#include <cuda_runtime.h>
#include <cuda.h>
#include <stdio.h>

// Define Backend as CUDA
#define VKFFT_BACKEND 1
#include "vkFFT/VkFFT.h"

// Context Struct
struct VkDCTContext {
    VkFFTApplication app;
    VkFFTConfiguration config;
    CUdevice device;
};

extern "C" {

/**
 * Create 3D DCT-I Plan
 */
void* create_dct3d_plan(uint64_t nx, uint64_t ny, uint64_t nz, int precision) {
    VkDCTContext* ctx = new VkDCTContext();
    if (!ctx) return nullptr;

    // Zero init
    ctx->app = {};
    ctx->config = {};

    // 1. Dimensions
    ctx->config.FFTdim = 3;
    ctx->config.size[0] = nx; // Fastest
    ctx->config.size[1] = ny;
    ctx->config.size[2] = nz; // Slowest

    // 2. DCT-I
    ctx->config.performDCT = 1;

    // 2b. Precision
    if (precision == 1) {
        ctx->config.doublePrecision = 1;
    }
    
    // 3. Normalize = 0 (manual normalization)
    ctx->config.normalize = 0; 

    // 4. Device
    if (cuInit(0) != CUDA_SUCCESS) {
         delete ctx;
         return nullptr;
    }

    if (cuDeviceGet(&ctx->device, 0) != CUDA_SUCCESS) {
        delete ctx;
        return nullptr;
    }
    ctx->config.device = &ctx->device;
    ctx->config.num_streams = 1;

    // 5. Initialize
    VkFFTResult res = initializeVkFFT(&ctx->app, ctx->config);
    
    if (res != VKFFT_SUCCESS) {
        printf("[VkDCT] Plan creation failed. Error code: %d\n", res);
        delete ctx;
        return nullptr;
    }

    return (void*)ctx;
}

/**
 * Execute Transform
 */
int exec_dct3d(void* plan_ptr, void* buffer, cudaStream_t stream, int inverse) {
    if (!plan_ptr) return -1;
    VkDCTContext* ctx = (VkDCTContext*)plan_ptr;

    // Update stream
    ctx->app.configuration.stream = &stream;

    VkFFTLaunchParams launchParams = {};
    launchParams.buffer = (void**)&buffer;
    launchParams.inputBuffer = (void**)&buffer;
    launchParams.outputBuffer = (void**)&buffer;
    
    // direction: -1 (Forward), 1 (Inverse)
    int dir = inverse ? 1 : -1;

    return (int)VkFFTAppend(&ctx->app, dir, &launchParams);
}

/**
 * Destroy Plan
 */
void destroy_dct3d_plan(void* plan_ptr) {
    if (plan_ptr) {
        VkDCTContext* ctx = (VkDCTContext*)plan_ptr;
        deleteVkFFT(&ctx->app);
        delete ctx;
    }
}

}
EOF

# Compile
# Use -arch=sm_60 to support Pascal and newer. 
# Since this is a shim, it mainly needs to act as host code, but includes CUDA headers.
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

# OS Detection: Linux Only
# We strictly target .so output with -fPIC
mkdir -p ${libdir}
nvcc -O3 --shared -Xcompiler -fPIC -arch=sm_60 -o ${libdir}/libvkfft_dct.so dct_shim.cu -I. -lcuda -lnvrtc

install_license LICENSE
"""

# Platforms - restricting to Linux/x86_64 for now as requested by typical GPU setups
platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
