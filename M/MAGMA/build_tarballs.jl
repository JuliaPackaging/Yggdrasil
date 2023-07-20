# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

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

augment_platform_block = CUDA.augment

platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)
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
