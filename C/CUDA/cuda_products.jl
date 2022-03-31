function cuda_products(cuda_version::VersionNumber;
    cupti_windows_library_name::AbstractString,
    cusolver_version::Union{VersionNumber,Nothing} = nothing,
    nvvm_windows_library_name::AbstractString)
    if (cusolver_version === nothing)
        cusolver_version = cuda_version
    end
    if cuda_version.major == 9 || cuda_version.major == 10 && cuda_version.minor == 0
        cuda_version_lib_extension = "$(cuda_version.major)$(cuda_version.minor)"
        cudart_version_lib_extension = cuda_version_lib_extension
        cufft_version_lib_extension = cuda_version_lib_extension
        cusolver_version_lib_extension = cuda_version_lib_extension
        curand_version_lib_extension = cuda_version_lib_extension
    elseif cuda_version.major == 10 && (cuda_version.minor == 1 || cuda_version.minor == 2)
        cuda_version_lib_extension = "$(cuda_version.major)"
        cudart_version_lib_extension = "$(cuda_version.major)$(cuda_version.minor)"
        cufft_version_lib_extension = cuda_version_lib_extension
        cusolver_version_lib_extension = cuda_version_lib_extension
        curand_version_lib_extension = cuda_version_lib_extension
    else
        cuda_version_lib_extension = "$(cuda_version.major)"
        cudart_version_lib_extension = "110"
        cufft_version_lib_extension = "10"
        cusolver_version_lib_extension = "$(cusolver_version.major)"
        curand_version_lib_extension = "10"
    end
    products = [
        LibraryProduct(["libcudart", "cudart64_$cudart_version_lib_extension"], :libcudart),
        FileProduct(["lib/libcudadevrt.a", "lib/cudadevrt.lib"], :libcudadevrt),
        LibraryProduct(["libcufft", "cufft64_$cufft_version_lib_extension"], :libcufft),
        LibraryProduct(["libcufftw", "cufftw64_$cufft_version_lib_extension"], :libcufftw),
        LibraryProduct(["libcublas", "cublas64_$cuda_version_lib_extension"], :libcublas),
        LibraryProduct(["libnvblas", "nvblas64_$cuda_version_lib_extension"], :libnvblas),
        LibraryProduct(["libcusparse", "cusparse64_$cuda_version_lib_extension"], :libcusparse),
        LibraryProduct(["libcusolver", "cusolver64_$cusolver_version_lib_extension"], :libcusolver),
        LibraryProduct(["libcurand", "curand64_$curand_version_lib_extension"], :libcurand),
        LibraryProduct(["libnppc", "nppc64_$cuda_version_lib_extension"], :libnppc),
        LibraryProduct(["libnppial", "nppial64_$cuda_version_lib_extension"], :libnppial),
        LibraryProduct(["libnppicc", "nppicc64_$cuda_version_lib_extension"], :libnppicc),
        LibraryProduct(["libnppidei", "nppidei64_$cuda_version_lib_extension"], :libnppidei),
        LibraryProduct(["libnppif", "nppif64_$cuda_version_lib_extension"], :libnppif),
        LibraryProduct(["libnppig", "nppig64_$cuda_version_lib_extension"], :libnppig),
        LibraryProduct(["libnppim", "nppim64_$cuda_version_lib_extension"], :libnppim),
        LibraryProduct(["libnppist", "nppist64_$cuda_version_lib_extension"], :libnppist),
        LibraryProduct(["libnppisu", "nppisu64_$cuda_version_lib_extension"], :libnppisu),
        LibraryProduct(["libnppitc", "nppitc64_$cuda_version_lib_extension"], :libnppitc),
        LibraryProduct(["libnpps", "npps64_$cuda_version_lib_extension"], :libnpps),
        LibraryProduct(["libnvvm", nvvm_windows_library_name], :libnvvm),
        FileProduct("share/libdevice/libdevice.10.bc", :libdevice),
        LibraryProduct(["libcupti", cupti_windows_library_name], :libcupti),
        LibraryProduct(["libnvToolsExt", "nvToolsExt64_1"], :libnvtoolsext),
        ExecutableProduct("nvdisasm", :nvdisasm),
    ]
    if !(cuda_version.major == 9
        || (cuda_version.major == 10 && cuda_version.minor == 0))
        products = vcat(products, [
            LibraryProduct(["libcublasLt", "cublasLt64_$cuda_version_lib_extension"], :libcublasLt),
        ])
    end
    if !(cuda_version.major == 9
        || (cuda_version.major == 10 && cuda_version.minor == 0)
        || (cuda_version.major == 10 && cuda_version.minor == 2)) # Excluded cusolverMg in CUDA 10.2 due to aarch64-linux-gnu
        products = vcat(products, [
            LibraryProduct(["libcusolverMg", "cusolverMg64_$cusolver_version_lib_extension"], :libcusolverMg)
        ])
    end
    if cuda_version.major == 9 || cuda_version.major == 10
        products = vcat(products, [
            LibraryProduct(["libnvgraph", "nvgraph64_$cuda_version_lib_extension"], :libnvgraph),
            LibraryProduct(["libnppicom", "nppicom64_$cuda_version_lib_extension"], :libnppicom),
        ])
    elseif cuda_version.major == 11
        products = vcat(products, [
            ExecutableProduct("compute-sanitizer", :compute_sanitizer),
        ])
    end
    return products
end
