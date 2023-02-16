using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

name = "JuliaNVTXCallbacks"
version = v"0.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/NVIDIA/NVTX",
              "e170594ac7cf1dac584da473d4ca9301087090c1"), # v3.1.0
    DirectorySource("./bundled"),
    GitSource("https://github.com/simonbyrne/NVTX.jl",
              "f562b128d79b56c6ea1b89e21a38c83d59c1e0a6"),          
]

# Bash recipe for building across all platforms
script = raw"""
atomic_patch -p1 $WORKSPACE/srcdir/patches/nvtx-linux-limits.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/nvtx-windows-case.patch
cd ${WORKSPACE}/srcdir/NVTX.jl/deps
mkdir -p ${libdir}
${CC} -std=c99 -O2 -fPIC -shared -I${WORKSPACE}/srcdir/NVTX/c/include -o ${libdir}/libjulia_nvtx_callbacks.${dlext} callbacks.c 
install_license /usr/share/licenses/MIT
"""

# CUDA platforms
platforms = [Platform("x86_64", "linux"),
             Platform("powerpc64le", "linux"),
             Platform("aarch64", "linux"),
             Platform("x86_64", "windows")]


# The products that we will ensure are always built
products = [
    LibraryProduct("libjulia_nvtx_callbacks", :libjulia_nvtx_callbacks),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
