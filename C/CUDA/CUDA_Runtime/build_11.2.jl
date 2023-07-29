script = raw"""
# First, find (true) CUDA toolkit directory in ~/.artifacts somewhere
CUDA_ARTIFACT_DIR=$(dirname $(dirname $(realpath $prefix/cuda/bin/ptxas${exeext})))
cd ${CUDA_ARTIFACT_DIR}

# Clear out our prefix
rm -rf ${prefix}/*

# license
install_license EULA.txt

# headers
mkdir -p ${prefix}/include
mv include/* ${prefix}/include
rm -rf ${prefix}/include/thrust

# binaries
mkdir -p ${bindir} ${libdir} ${prefix}/lib ${prefix}/share
if [[ ${target} == *-linux-gnu ]]; then
    # CUDA Runtime
    mv lib64/libcudart.so* lib64/libcudadevrt.a ${libdir}

    # CUDA FFT Library
    mv lib64/libcufft.so* lib64/libcufftw.so* ${libdir}

    # CUDA BLAS Library
    mv lib64/libcublas.so* lib64/libcublasLt.so* ${libdir}

    # CUDA Sparse Matrix Library
    mv lib64/libcusparse.so* ${libdir}

    # CUDA Linear Solver Library
    mv lib64/libcusolver.so* ${libdir}

    # CUDA Linear Solver Multi GPU Library
    mv lib64/libcusolverMg.so* ${libdir}

    # CUDA Random Number Generation Library
    mv lib64/libcurand.so* ${libdir}

    # NVIDIA Optimizing Compiler Library
    mv nvvm/lib64/libnvvm.so* ${libdir}

    # NVIDIA Runtime Compilation Library
    mv lib64/libnvrtc.so* ${libdir}
    mv lib64/libnvrtc-builtins.so* ${libdir}

    # NVIDIA Common Device Math Functions Library
    mkdir ${prefix}/share/libdevice
    mv nvvm/libdevice/libdevice.10.bc ${prefix}/share/libdevice

    # CUDA Profiling Tools Interface (CUPTI) Library
    mv extras/CUPTI/lib64/libcupti.so* ${libdir}
    mv extras/CUPTI/lib64/libnvperf_host.so* ${libdir}
    mv extras/CUPTI/lib64/libnvperf_target.so* ${libdir}

    # Compute Sanitizer
    rm -r compute-sanitizer/{docs,include}
    mv compute-sanitizer/* ${bindir}

    # Additional binaries
    mv bin/ptxas ${bindir}
    mv bin/nvdisasm ${bindir}
    mv bin/nvlink ${bindir}

    # Convert the static compiler library to a dynamic one
    ${CC} -std=c99 -fPIC -shared -lm \
          -Llib64 -Wl,--whole-archive -lnvptxcompiler_static -Wl,--no-whole-archive \
          -o ${libdir}/libnvPTXCompiler.so
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    # CUDA Runtime
    mv bin/cudart64_*.dll ${bindir}
    mv lib/x64/cudadevrt.lib ${prefix}/lib

    # CUDA FFT Library
    mv bin/cufft64_*.dll bin/cufftw64_*.dll ${bindir}

    # CUDA BLAS Library
    mv bin/cublas64_*.dll bin/cublasLt64_*.dll ${bindir}

    # CUDA Sparse Matrix Library
    mv bin/cusparse64_*.dll ${bindir}

    # CUDA Linear Solver Library
    mv bin/cusolver64_*.dll ${bindir}

    # CUDA Linear Solver Multi GPU Library
    mv bin/cusolverMg64_*.dll ${bindir}

    # CUDA Random Number Generation Library
    mv bin/curand64_*.dll ${bindir}

    # NVIDIA Optimizing Compiler Library
    mv nvvm/bin/nvvm64_*.dll ${bindir}

    # NVIDIA Runtime Compilation Library
    mv bin/nvrtc64_* ${bindir}
    mv bin/nvrtc-builtins64_* ${bindir}

    # NVIDIA Common Device Math Functions Library
    mkdir ${prefix}/share/libdevice
    mv nvvm/libdevice/libdevice.10.bc ${prefix}/share/libdevice

    # CUDA Profiling Tools Interface (CUPTI) Library
    mv extras/CUPTI/lib64/cupti64_*.dll ${bindir}
    mv extras/CUPTI/lib64/nvperf_host.dll* ${libdir}
    mv extras/CUPTI/lib64/nvperf_target.dll* ${libdir}

    # Compute Sanitizer
    rm -r compute-sanitizer/{docs,include}
    mv compute-sanitizer/* ${bindir}

    # Additional binaries
    mv bin/ptxas.exe ${bindir}
    mv bin/nvdisasm.exe ${bindir}
    mv bin/nvlink.exe ${bindir}

    # Convert the static compiler library to a dynamic one
    # XXX: nvptxcompiler_static.lib is a MSVC-generated library, which doesn't work with
    #      our toolchain (__GSHandlerCheck and __security_check_cookie are missing)
    #${CC} -std=c99 -shared -lm \
    #      -Llib/x64 -Wl,--whole-archive -lnvptxcompiler_static -Wl,--no-whole-archive \
    #      -o ${libdir}/nvPTXCompiler.dll

    # Fix permissions
    chmod +x ${bindir}/*.{exe,dll}
fi
"""

function get_products(platform)
    products = [
        LibraryProduct(["libcudart", "cudart64_110"], :libcudart),
        LibraryProduct(["libnvvm", "nvvm64_40_0"], :libnvvm),
        LibraryProduct(["libnvrtc", "nvrtc64_112_0"], :libnvrtc),
        LibraryProduct(["libnvrtc-builtins", "nvrtc-builtins64_112"], :libnvrtc_builtins),
        LibraryProduct(["libcufft", "cufft64_10"], :libcufft),
        LibraryProduct(["libcublas", "cublas64_11"], :libcublas),
        LibraryProduct(["libcublasLt", "cublasLt64_11"], :libcublasLt),
        LibraryProduct(["libcusparse", "cusparse64_11"], :libcusparse),
        LibraryProduct(["libcusolver", "cusolver64_11"], :libcusolver),
        LibraryProduct(["libcusolverMg", "cusolverMg64_11"], :libcusolverMg),
        LibraryProduct(["libcurand", "curand64_10"], :libcurand),
        LibraryProduct(["libcupti", "cupti64_2020.3.1"], :libcupti),
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

platforms = [Platform("x86_64", "linux"; cuda="11.2"),
             Platform("powerpc64le", "linux"; cuda="11.2"),
             Platform("x86_64", "windows"; cuda="11.2")]
