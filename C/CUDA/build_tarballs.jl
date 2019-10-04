using BinaryBuilder

name = "CUDA"
version = v"10.1.243"

sources = [
    "http://developer.download.nvidia.com/compute/cuda/10.1/Prod/cluster_management/cuda_cluster_pkgs_10.1.243_418.87.00_rhel6.tar.gz" =>
    "024b61d193105aef37241c89e511f0fec9dcecc2af416f2a1151f2a4dbbb3c29",
    "http://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.243_mac.dmg" =>
    "432a2f07a793f21320edc5d10e7f68a8e4e89465c31e1696290bdb0ca7c8c997",
    "http://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.243_426.00_win10.exe" =>
    "35d3c99c58dd601b2a2caa28f44d828cae1eaf8beb70702732585fa001cd8ad7",
]

# CUDA is weirdly organized, with several tools in bin/lib directories, some in dedicated
# subproject folders, and others in a catch-all extras/ directory. to simplify using
# the resulting binaries, we reorganize everything using a flat bin/lib structure.

script = raw"""
cd ${WORKSPACE}/srcdir

apk add p7zip rpm

if [[ ${target} == x86_64-linux-gnu ]]; then
    cd cuda_cluster_pkgs*
    rpm2cpio cuda-cluster-runtime*.rpm | cpio -idmv
    rpm2cpio cuda-cluster-devel*.rpm | cpio -idmv
    cd usr/local/cuda*

    # toplevel
    mv bin ${prefix}
    mv targets/x86_64-linux/lib ${prefix}
    mkdir ${prefix}/share

    # nested
    for project in nvvm extras/CUPTI; do
        [[ -d ${project}/bin ]] && mv ${project}/bin/* ${prefix}/bin
        [[ -d ${project}/lib64 ]] && mv ${project}/lib64/* ${prefix}/lib
    done
    mv nvvm/libdevice ${prefix}/share

    # clean up
    rm    ${prefix}/bin/{nvcc,nvcc.profile,cicc,cudafe++}       # CUDA C/C++ compiler
    rm -r ${prefix}/bin/crt/
    rm    ${prefix}/bin/{gpu-library-advisor,bin2c}             # C/C++ utilities
    rm    ${prefix}/bin/{nvvp,nsight,computeprof}               # requires Java
    rm    ${prefix}/lib/*.a                                     # we can't link statically
    rm -r ${prefix}/lib/stubs/                                  # stubs are a C/C++ thing
    rm    ${prefix}/bin/cuda-install-samples-*.sh
    rm    ${prefix}/bin/nsight_ee_plugins_manage.sh
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    7z x ${WORKSPACE}/srcdir/*-cuda_*_win10.exe -bb

    # toplevel
    mkdir -p ${prefix}/bin ${prefix}/share
    # no lib folder; we don't ship static libs

    # nested
    for project in cuobjdump memcheck nvcc nvcc/nvvm nvdisasm curand cusparse npp cufft cublas cudart cusolver nvrtc nvgraph nvprof nvprune; do
        [[ -d ${project}/bin ]] && mv ${project}/bin/* ${prefix}/bin
    done
    mv nvcc/nvvm/libdevice ${prefix}/share
    mv cupti/extras/CUPTI/lib64/* ${prefix}/bin/

    # clean up
    rm    ${prefix}/bin/{nvcc,cicc,cudafe++}.exe   # CUDA C/C++ compiler
    rm    ${prefix}/bin/nvcc.profile
    rm -r ${prefix}/bin/crt/
    rm    ${prefix}/bin/bin2c.exe                               # C/C++ utilities
    rm    ${prefix}/bin/*.lib                                   # we can't link statically

    # Make .exe's executable
    chmod +x ${prefix}/bin/*.exe

elif [[ ${target} == x86_64-apple-darwin* ]]; then
    7z x ${WORKSPACE}/srcdir/*-cuda_*_mac.dmg
    7z x 5.hfs
    tar -zxvf CUDAMacOSXInstaller/CUDAMacOSXInstaller.app/Contents/Resources/payload/cuda_mac_installer_tk.tar.gz
    cd Developer/NVIDIA/CUDA-*/

    # toplevel
    mv bin ${prefix}
    mv lib ${prefix}
    mkdir ${prefix}/share

    # nested
    for project in nvvm extras/CUPTI; do
        [[ -d ${project}/bin ]] && mv ${project}/bin/* ${prefix}/bin
        [[ -d ${project}/lib ]] && mv ${project}/lib/* ${prefix}/lib
    done
    mv nvvm/libdevice ${prefix}/share

    # clean up
    rm    ${prefix}/bin/{nvcc,nvcc.profile,cicc,cudafe++}       # CUDA C/C++ compiler
    rm -r ${prefix}/bin/crt/
    rm    ${prefix}/bin/{gpu-library-advisor,bin2c}             # C/C++ utilities
    rm    ${prefix}/bin/{nvvp,nsight,computeprof}               # requires Java
    rm    ${prefix}/lib/*.a                                     # we can't link statically
    rm -r ${prefix}/lib/stubs/                                  # stubs are a C/C++ thing
    rm    ${prefix}/bin/uninstall_cuda_*.pl
    rm    ${prefix}/bin/nsight_ee_plugins_manage.sh
    rm    ${prefix}/bin/.cuda_toolkit_uninstall_manifest_do_not_delete.txt
fi
"""

platforms = [
    Linux(:x86_64),
    Windows(:x86_64),
    MacOS(:x86_64),
]

# cuda-gdb, libnvjpeg, libOpenCL, libaccinj(64), libnvperf_host, libnvperf_target only on linux

products = [
    ExecutableProduct("nvprof", :nvprof),
    ExecutableProduct("ptxas", :ptxas),
    LibraryProduct(["libcudart", "cudart", "cudart64_101"], :libcudart),
    LibraryProduct(["libcufft", "cufft", "cufft64_10"], :libcufft),
    LibraryProduct(["libcufftw", "cufftw", "cufftw64_10"], :libcufftw),
    LibraryProduct(["libcurand", "curand", "curand64_10"], :libcurand),
    LibraryProduct(["libcublas", "cublas", "cublas64_10"], :libcublas),
    LibraryProduct(["libcusolver", "cusolver", "cusolver64_10"], :libcusolver),
    LibraryProduct(["libcusparse", "cusparse", "cusparse64_10"], :libcusparse),
    LibraryProduct(["libnvrtc", "nvrtc", "nvrtc64_101_0"], :libnvrtc),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
