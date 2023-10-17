function get_products(platform)
    products = [
        LibraryProduct(["libcudart", "cudart64_110"], :libcudart),
        LibraryProduct(["libnvvm", "nvvm64_40_0"], :libnvvm),
        LibraryProduct(["libnvrtc", "nvrtc64_112_0"], :libnvrtc),
        LibraryProduct(["libnvrtc-builtins", "nvrtc-builtins64_115"], :libnvrtc_builtins),
        LibraryProduct(["libcufft", "cufft64_10"], :libcufft),
        LibraryProduct(["libcublas", "cublas64_11"], :libcublas),
        LibraryProduct(["libcublasLt", "cublasLt64_11"], :libcublasLt),
        LibraryProduct(["libcusparse", "cusparse64_11"], :libcusparse),
        LibraryProduct(["libcusolver", "cusolver64_11"], :libcusolver),
        LibraryProduct(["libcusolverMg", "cusolverMg64_11"], :libcusolverMg),
        LibraryProduct(["libcurand", "curand64_10"], :libcurand),
        LibraryProduct(["libcupti", "cupti64_2021.3.1"], :libcupti),
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
