using BinaryBuilder

name = "cuPDLPx"
version = v"0.1.0"  # Update to your release version

# Source tarball from GitHub
# sources = [
#     ArchiveSource("https://github.com/MIT-Lu-Lab/cuPDLPx/archive/refs/tags/v$(version).tar.gz",
#                   "<sha256sum-of-release-tarball>"),
# ]

sources = [
    GitSource("https://github.com/ZedongPeng/cuPDLPx.git","6c9c99472023aae268c2dae690eadd1a3d37733c"),
]

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    # Platform("aarch64", "linux"; libc="glibc"),
]


# Dependencies: CUDA runtime and libraries
dependencies = [
    Dependency("CUDA_Runtime_jll"),
    Dependency("CUDA_full_jll"),
    # Dependency("CUBLAS_jll"),
    # Dependency("CUSPARSE_jll"),
]

script = raw"""
#!/bin/bash
set -euxo pipefail

# Ensure CUDA paths are visible
export CUDA_HOME="${prefix}"
export PATH="${CUDA_HOME}/bin:$PATH"
export LD_LIBRARY_PATH="${CUDA_HOME}/lib64:$LD_LIBRARY_PATH"

# Build and install using the provided Makefile
make -C $WORKSPACE/srcdir/cuPDLPx PREFIX=$prefix install
"""

# Installed products
products = [
    LibraryProduct("libcupdlpx", :libcupdlpx),  # shared library
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;julia_compat = "1.9")
