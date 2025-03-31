using BinaryBuilder, Pkg

name = "NVTX"
version = v"3.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/NVIDIA/NVTX",
              "6230bdf710bc94f44d433acceba735aaa9090ba5"), # v3.1.1 tag
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p ${libdir}
if [[ "${target}" == *-linux-* ]]; then
    CFLAGS="-fPIC"
    LIBS="-ldl"
fi
${CC} -std=c99 -O2 ${CFLAGS} -shared ${LIBS} -I${prefix}/cuda/include -I${WORKSPACE}/srcdir/NVTX/c/include -o ${libdir}/libnvToolsExt.${dlext} nvtx.c
install_license ${WORKSPACE}/srcdir/NVTX/LICENSE.txt
"""

# CUDA platforms
platforms = [Platform("x86_64", "linux"),
             Platform("powerpc64le", "linux"),
             Platform("aarch64", "linux"),
             Platform("x86_64", "windows")]


# The products that we will ensure are always built
products = [
    LibraryProduct("libnvToolsExt", :libnvToolsExt)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("CUDA_full_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
