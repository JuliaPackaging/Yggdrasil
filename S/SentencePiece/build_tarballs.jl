# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SentencePiece"
version = v"0.1.92"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/google/sentencepiece/archive/v0.1.92.tar.gz", "6e9863851e6277862083518cc9f96211f334215d596fc8c65e074d564baeef0c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd sentencepiece*
mkdir cmbuild
cd cmbuild/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsentencepiece_train", :libsentencepiece_train),
    ExecutableProduct("spm_normalize", :spm_normalize),
    ExecutableProduct("spm_encode", :spm_encode),
    ExecutableProduct("spm_export_vocab", :spm_export_vocab),
    ExecutableProduct("spm_train", :spm_train),
    LibraryProduct("libsentencepiece", :libsentencepiece),
    ExecutableProduct("spm_decode", :spm_decode)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="gperftools_jll", uuid="c8ae51e6-ca1b-5cf7-8aa4-ff5973bfb1e4"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
