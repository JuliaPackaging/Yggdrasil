using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "libNVVM"
version = v"4.0"

sources = []

script = raw"""
# First, find (true) CUDA toolkit directory in ~/.artifacts somewhere
CUDA_ARTIFACT_DIR=$(dirname $(dirname $(realpath $prefix/cuda/bin/ptxas${exeext})))
cd ${CUDA_ARTIFACT_DIR}

# Clear out our prefix
rm -rf ${prefix}/*

# license
install_license EULA.txt

mkdir -p ${bindir} ${libdir} ${prefix}/include ${prefix}/share
if [[ ${target} == *-linux-gnu ]]; then
    mv nvvm/lib64/libnvvm.so* ${libdir}
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    mv nvvm/bin/nvvm64_*.dll ${bindir}
    chmod +x ${bindir}/*.dll
fi
mv nvvm/include/* ${prefix}/include/
mv nvvm/libdevice ${prefix}/share/
"""

platforms = [Platform("x86_64", "linux"),
             Platform("powerpc64le", "linux"),
             Platform("aarch64", "linux"),
             Platform("x86_64", "windows")]

products = [
    LibraryProduct(["libnvvm", "nvvm64_40_0"], :libnvvm),
    FileProduct("share/libdevice/libdevice.10.bc", :libdevice),
]

dependencies = [BuildDependency(PackageSpec(name="CUDA_full_jll", version=v"12.1.1"))]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
