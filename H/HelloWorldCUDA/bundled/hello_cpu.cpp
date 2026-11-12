#include <cmath>

// The same computation as hello_cuda.cu, on the CPU.
extern "C" float hello_cuda_norm(int n) {
    float sum = 0.0f;
    for (int i = 0; i < n; i++)
        sum += 1.0f;
    return std::sqrt(sum);
}
