# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "MAGMA"
version = v"2.7.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://icl.utk.edu/projectsfiles/magma/downloads/magma-2.7.0.tar.gz", "fda1cbc4607e77cacd8feb1c0f633c5826ba200a018f647f1c5436975b39fd18"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/magma-*

cp ../make.inc .
make -j${nproc} sparse-shared
make install prefix=${prefix}
install_license COPYRIGHT
"""

# Dependencies that must be installed before this package can be built
cuda_full_versions = Dict(
    v"11.0" => v"11.0.3",
)
cuda_version = v"11.0"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = expand_cxxstring_abis(supported_platforms())
cuda_platforms = expand_cxxstring_abis(Platform("x86_64", "linux"; 
                                        cuda=CUDA.platform(cuda_version)))

for p in cuda_platforms
    push!(platforms, p)
end


# The products that we will ensure are always built
products = [
    LibraryProduct("libmagma", :libmagma),
    LibraryProduct("libmagma_sparse", :libmagma_sparse)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # You can only specify one cuda version in the deps. To build against more than 
    # one cuda version, you have to include them as Archive Sources. (see Torch_jll)
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=cuda_full_versions[cuda_version]), platforms=cuda_platforms),
    RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll"), platforms=cuda_platforms),
    Dependency("libblastrampoline_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, cuda_platforms, products, dependencies; 
                preferred_gcc_version=v"8", 
                julia_compat="1.6",
                augment_platform_block=CUDA.augment)