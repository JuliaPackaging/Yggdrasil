function get_products(platform)
    [
        LibraryProduct(["libcudart", "cudart64_110"], :libcudart),
        LibraryProduct(["libcufft", "cufft64_10"], :libcufft),
        LibraryProduct(["libcublas", "cublas64_11"], :libcublas),
        LibraryProduct(["libcublasLt", "cublasLt64_11"], :libcublasLt),
        LibraryProduct(["libcusparse", "cusparse64_11"], :libcusparse),
        LibraryProduct(["libcusolver", "cusolver64_11"], :libcusolver),
        LibraryProduct(["libcusolverMg", "cusolverMg64_11"], :libcusolverMg),
        LibraryProduct(["libcurand", "curand64_10"], :libcurand),
        LibraryProduct(["libcupti", "cupti64_2022.2.1"], :libcupti),
        LibraryProduct(["libnvperf_host", "nvperf_host"], :libnvperf_host),
        LibraryProduct(["libnvperf_target", "nvperf_target"], :libnvperf_target),
        LibraryProduct(["libnvrtc", "nvrtc64_112_0"], :libnvrtc),
        LibraryProduct(["libnvrtc-builtins", "nvrtc-builtins64_117"], :libnvrtc_builtins),
    ]
end
