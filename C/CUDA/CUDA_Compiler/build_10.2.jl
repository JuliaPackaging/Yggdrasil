# CUDA 10.2 has no redistributable archives, so like CUDA_Runtime_jll we repackage the
# relevant parts of the CUDA_SDK_jll build (which comes from the toolkit installers, and
# from the L4T apt packages on Jetson).

get_script() = raw"""
# First, find (true) CUDA toolkit directory in ~/.artifacts somewhere
CUDA_ARTIFACT_DIR=$(dirname $(dirname $(realpath $prefix/cuda/bin/ptxas${exeext})))
cd ${CUDA_ARTIFACT_DIR}

# Clear out our prefix
rm -rf ${prefix}/*

# license
install_license EULA.txt

# binaries
mkdir -p ${bindir} ${libdir} ${prefix}/lib ${prefix}/share ${prefix}/nvvm
if [[ ${target} == *-linux-gnu ]]; then
    mv lib64/libcudadevrt.a ${libdir}

    mv nvvm/libdevice ${prefix}/nvvm
    mv nvvm/lib64 ${prefix}/nvvm

    mv bin/ptxas ${bindir}
    mv bin/nvlink ${bindir}
    mv bin/nvdisasm ${bindir}

    mv lib64/libnvrtc.so* ${libdir}
    mv lib64/libnvrtc-builtins.so* ${libdir}
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    mv lib/x64/cudadevrt.lib ${prefix}/lib

    mv nvvm/libdevice ${prefix}/nvvm
    mv nvvm/bin ${prefix}/nvvm

    mv bin/ptxas.exe ${bindir}
    mv bin/nvlink.exe ${bindir}
    mv bin/nvdisasm.exe ${bindir}

    mv bin/nvrtc64_* ${bindir}
    mv bin/nvrtc-builtins64_* ${bindir}

    # Fix permissions
    chmod +x ${bindir}/*.exe ${bindir}/*.dll ${prefix}/nvvm/bin/*.dll
fi
"""

get_products() = [
    FileProduct(["lib/libcudadevrt.a", "lib/cudadevrt.lib"], :libcudadevrt),
    FileProduct("nvvm/libdevice/libdevice.10.bc", :libdevice),
    LibraryProduct(["libnvvm", "nvvm64_33_0"], :libnvvm, ["nvvm/lib64", "nvvm/bin"]),
    LibraryProduct(["libnvrtc", "nvrtc64_102_0"], :libnvrtc),
    LibraryProduct(["libnvrtc-builtins", "nvrtc-builtins64_102"], :libnvrtc_builtins),
    ExecutableProduct("ptxas", :ptxas),
    ExecutableProduct("nvdisasm", :nvdisasm),
    ExecutableProduct("nvlink", :nvlink),
]
