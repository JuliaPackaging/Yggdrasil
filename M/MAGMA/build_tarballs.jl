# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "MAGMA"
version = v"2.9.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://icl.utk.edu/projectsfiles/magma/downloads/magma-$(version).tar.gz",
                  "ff77fd3726b3dfec3bfb55790b06480aa5cc384396c2db35c56fdae4a82c641c"),
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

augment_platform_block = CUDA.augment

# Note: Hopper should still build with CUDA v11.8
# on x86_64, but aarch64 requires CUDA v12.0
platforms = CUDA.supported_platforms(min_version=v"12")
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libmagma", :libmagma; dont_dlopen=true),
    LibraryProduct("libmagma_sparse", :libmagma_sparse; dont_dlopen=true)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libblastrampoline_jll", compat="5.1.1"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, [dependencies; cuda_deps];
                   preferred_gcc_version=v"8",
                   julia_compat="1.8",
                   augment_platform_block,
                   skip_audit=true, dont_dlopen=true)
end
