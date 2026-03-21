function get_products(platform)
    [
        LibraryProduct(["libcudart", "cudart64_13"], :libcudart),
        LibraryProduct(["libcufft", "cufft64_12"], :libcufft),
        LibraryProduct(["libcublas", "cublas64_13"], :libcublas),
        LibraryProduct(["libcublasLt", "cublasLt64_13"], :libcublasLt),
        LibraryProduct(["libcusparse", "cusparse64_12"], :libcusparse),
        LibraryProduct(["libcusolver", "cusolver64_12"], :libcusolver),
        LibraryProduct(["libcusolverMg", "cusolverMg64_12"], :libcusolverMg),
        LibraryProduct(["libcurand", "curand64_10"], :libcurand),
        LibraryProduct(["libcupti", "cupti64_2025.3.1"], :libcupti),
        LibraryProduct(["libnvperf_host", "nvperf_host"], :libnvperf_host),
        LibraryProduct(["libnvperf_target", "nvperf_target"], :libnvperf_target),
        LibraryProduct(["libnvrtc", "nvrtc64_130_0"], :libnvrtc),
        LibraryProduct(["libnvrtc-builtins", "nvrtc-builtins64_130"], :libnvrtc_builtins),
        LibraryProduct(["libnvJitLink", "nvJitLink_130_0"], :libnvJitLink),
    ]
end
