function get_products(platform)
    products = [
        LibraryProduct(["libcudart", "cudart64_12"], :libcudart),
        LibraryProduct(["libnvvm", "nvvm64_40_0"], :libnvvm),
        LibraryProduct(["libnvJitLink", "nvJitLink_120_0"], :libnvJitLink),
        LibraryProduct(["libnvrtc", "nvrtc64_120_0"], :libnvrtc),
        LibraryProduct(["libnvrtc-builtins", "nvrtc-builtins64_121"], :libnvrtc_builtins),
        LibraryProduct(["libcufft", "cufft64_11"], :libcufft),
        LibraryProduct(["libcublas", "cublas64_12"], :libcublas),
        LibraryProduct(["libcublasLt", "cublasLt64_12"], :libcublasLt),
        LibraryProduct(["libcusparse", "cusparse64_12"], :libcusparse),
        LibraryProduct(["libcusolver", "cusolver64_11"], :libcusolver),
        LibraryProduct(["libcusolverMg", "cusolverMg64_11"], :libcusolverMg),
        LibraryProduct(["libcurand", "curand64_10"], :libcurand),
        LibraryProduct(["libcupti", "cupti64_2023.1.1"], :libcupti),
        LibraryProduct(["libnvperf_host", "nvperf_host"], :libnvperf_host),
        LibraryProduct(["libnvperf_target", "nvperf_target"], :libnvperf_target),
        FileProduct(["lib/libcudadevrt.a", "lib/cudadevrt.lib"], :libcudadevrt),
        FileProduct("share/libdevice/libdevice.10.bc", :libdevice),
        ExecutableProduct("ptxas", :ptxas),
        ExecutableProduct("nvdisasm", :nvdisasm),
        ExecutableProduct("nvlink", :nvlink),
        ExecutableProduct("compute-sanitizer", :compute_sanitizer),
    ]
    if !Sys.iswindows(platform)
        push!(products, LibraryProduct("libnvPTXCompiler", :libnvPTXCompiler))
    end
    return products
end
