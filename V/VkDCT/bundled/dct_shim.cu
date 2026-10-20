// dct_shim.cu
#include <cuda_runtime.h>
#include <cuda.h>
#include <stdio.h>

// Define Backend as CUDA
#define VKFFT_BACKEND 1

// Directly include the header since we are in its directory
#include "vkFFT.h"

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
