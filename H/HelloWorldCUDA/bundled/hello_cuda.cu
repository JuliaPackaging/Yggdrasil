#include <cstdio>
#include <cublas_v2.h>
#include <cuda_runtime.h>

__global__ void fill_ones(float *x, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n)
        x[i] = 1.0f;
}

// Fill with a CUDA kernel, then compute the norm with cuBLAS.
extern "C" float hello_cuda_norm(int n) {
    float *x = nullptr, norm = -1.0f;
    cublasHandle_t blas = nullptr;
    cudaError_t err = cudaMalloc(&x, n * sizeof(float));
    if (err != cudaSuccess) {
        std::fprintf(stderr, "cudaMalloc: %s\n", cudaGetErrorString(err));
        return norm;
    }
    fill_ones<<<1, 128>>>(x, n);
    err = cudaGetLastError();
    if (err != cudaSuccess) {
        std::fprintf(stderr, "launch: %s\n", cudaGetErrorString(err));
    } else if (cublasCreate(&blas) == CUBLAS_STATUS_SUCCESS) {
        cublasSnrm2(blas, n, x, 1, &norm);
        cublasDestroy(blas);
    }
    cudaFree(x);
    return norm;
}
