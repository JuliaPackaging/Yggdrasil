# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MAGMA"
version = v"2.5.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Roger-luo/MAGMA/archive/v2.5.2.tar.gz", "dc3b90182825721d9b9ca1deb8afb2ff547ee41991ed698225832693a30a64ab")
]

# Bash recipe for building across all platforms
script = raw"""
export CUDADIR="${prefix}/cuda"
export OPENBLASDIR="${prefix}"
export PATH=${PATH}:${WORKSPACE}/destdir/cuda/bin
cd ${WORKSPACE}/srcdir/MAGMA-2.5.2/
make lib -j${nproc}
make install -j${nproc}
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libmagma", :libmagma)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CUDA_full_jll", uuid="4f82f1eb-248c-5f56-a42e-99106d144614"))
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")
