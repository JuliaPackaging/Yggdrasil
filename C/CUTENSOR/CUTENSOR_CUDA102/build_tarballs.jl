using BinaryBuilder

cuda_version = v"10.2.89"   # NOTE: could be less specific

# NOTE: the same build is used for CUDA 10.1, but we can't express that with BinaryBuilder
sources_linux = [
    ArchiveSource("https://developer.download.nvidia.com/assets/gameworks/downloads/secure/cuTensor/libcutensor-linux-x86_64-1.0.1.tar.gz",
                  "ca6122b3f15511cd33a5eb7f911cff1553def1d3ff0b9270e62ef08f1a94f2aa")
]

script = raw"""
cd ${WORKSPACE}/srcdir
if [[ ${target} == x86_64-linux-gnu ]]; then
    cd libcutensor
    find .

    install_license license.pdf

    mv lib/10.2/libcutensor.so* ${libdir}
    mv include/* ${prefix}/include
fi
"""

include("../common.jl")
