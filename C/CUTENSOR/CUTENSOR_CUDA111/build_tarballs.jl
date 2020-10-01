using BinaryBuilder

cuda_version = v"11.1.0"   # NOTE: could be less specific

script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir
if [[ ${target} == *-linux-gnu ]]; then
    cd libcutensor
    find .

    install_license license.pdf

    mv lib/11.1/libcutensor.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    apk add p7zip
    7z x libcutensor*.exe
    cd libcutensor

    cd libcutensor
    find .

    install_license license.pdf

    mv lib/11.1/cutensor.dll ${libdir}
    mv include/* ${prefix}/include
fi
"""

include("../common.jl")
