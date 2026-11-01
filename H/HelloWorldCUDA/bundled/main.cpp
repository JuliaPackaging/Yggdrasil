#include <cstdio>

extern "C" float hello_cuda_norm(int n);

int main() {
    float norm = hello_cuda_norm(4);
    std::printf("Hello, CUDA! norm = %g\n", norm);
    return norm > 1.99f && norm < 2.01f ? 0 : 1;
}
