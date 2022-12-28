# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "MAGMA"
version = v"2.7.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://icl.utk.edu/projectsfiles/magma/downloads/magma-2.7.0.tar.gz", "fda1cbc4607e77cacd8feb1c0f633c5826ba200a018f647f1c5436975b39fd18"),
    DirectorySource("./bundled"),
    # 10.x isn't supported apparently.
    # ArchiveSource("https://github.com/JuliaBinaryWrappers/CUDA_full_jll.jl/releases/download/CUDA_full-v10.2.89%2B5/CUDA_full.v10.2.89.x86_64-linux-gnu.tar.gz", "60e6f614db3b66d955b7e6aa02406765e874ff475c69e2b4a04eb95ba65e4f3b"; unpack_target = "CUDA_full.v10.2"),
    ArchiveSource("https://github.com/JuliaBinaryWrappers/CUDA_full_jll.jl/releases/download/CUDA_full-v11.3.1%2B1/CUDA_full.v11.3.1.x86_64-linux-gnu.tar.gz", "9ae00d36d39b04e8e99ace63641254c93a931dcf4ac24c8eddcdfd4625ab57d6"; unpack_target = "CUDA_full.v11.3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/magma-*
cuda_version=`echo $bb_full_target | sed -E -e 's/.*cuda\+([0-9]+\.[0-9]+).*/\1/'`
cuda_version_major=`echo $cuda_version | cut -d . -f 1`
cuda_version_minor=`echo $cuda_version | cut -d . -f 2`
cuda_full_path="$WORKSPACE/srcdir/CUDA_full.v$cuda_version/cuda"
export PATH=$PATH:${cuda_full_path}/bin
export CUDADIR=${cuda_full_path}
cp ../make.inc .
make -j2 sparse-shared
make install prefix=${prefix}
install_license COPYRIGHT
"""

cuda_platforms = [
    # Platform("x86_64", "Linux"; cuda = "10.2"),
    Platform("x86_64", "Linux"; cuda = "11.3"),
]
platforms = expand_cxxstring_abis(cuda_platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libmagma", :libmagma),
    LibraryProduct("libmagma_sparse", :libmagma_sparse)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # You can only specify one cuda version in the deps. To build against more than 
    # one cuda version, you have to include them as Archive Sources. (see Torch_jll)
    RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
    Dependency("libblastrampoline_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
                preferred_gcc_version=v"8", 
                julia_compat="1.6",
                augment_platform_block=CUDA.augment)