# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "MAGMA"
version = v"2.7.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://icl.utk.edu/projectsfiles/magma/downloads/magma-$(version).tar.gz",
                  "fda1cbc4607e77cacd8feb1c0f633c5826ba200a018f647f1c5436975b39fd18"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/magma*

export CUDADIR=${WORKSPACE}/destdir/cuda
export PATH=${PATH}:${CUDADIR}
cp ../make.inc .
# Patch to _64_ suffixes
atomic_patch -p1 ../0001-mangle-to-ILP64.patch
# reduce parallelism since otherwise the builder may OOM.
(( nproc=1+nproc/3 ))
make -j${nproc} sparse-shared
make install prefix=${prefix}
install_license COPYRIGHT
"""

cuda_platforms = [
    # CUDA 10.2 would not build, missing symbols.
    # Platform("x86_64", "Linux"; cuda = "10.2"),
    Platform("x86_64", "Linux"; cuda = "11.3"),
]
platforms = expand_cxxstring_abis(cuda_platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libmagma", :libmagma; dont_dlopen=true),
    LibraryProduct("libmagma_sparse", :libmagma_sparse; dont_dlopen=true)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # You can only specify one cuda version in the deps. To build against more than
    # one cuda version, you have to include them as Archive Sources. (see Torch_jll)
    RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=CUDA.full_version(v"11.0"))),
    Dependency("libblastrampoline_jll", compat="5.1.1"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                preferred_gcc_version=v"8",
                julia_compat="1.8",
                augment_platform_block=CUDA.augment)
