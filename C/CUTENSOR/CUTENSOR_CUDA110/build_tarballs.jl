using BinaryBuilder

cuda_version = v"11.0.2"   # NOTE: could be less specific

script = raw"""
cd ${WORKSPACE}/srcdir
if [[ ${target} == x86_64-linux-gnu ]]; then
    cd libcutensor
    find .

    install_license license.pdf

    mv lib/11.0/libcutensor.so* ${libdir}
    mv include/* ${prefix}/include
fi
"""

include("../common.jl")
