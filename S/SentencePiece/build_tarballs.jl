# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SentencePiece"
version = v"0.1.96"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/google/sentencepiece/archive/refs/tags/v$(version).tar.gz",
                  "5198f31c3bb25e685e9e68355a3bf67a1db23c9e8bdccc33dc015f496a44df7a"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sentencepiece*

# Resolve FreeBSD build issue per https://github.com/google/sentencepiece/pull/693/files
if [[ "${target}" == *-freebsd* ]]; then
    atomic_patch -p1 ../patches/freebsd.patch
fi

mkdir build && cd build/

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
    Dependency(PackageSpec(name="gperftools_jll", uuid="c8ae51e6-ca1b-5cf7-8aa4-ff5973bfb1e4");
               # Copy from platforms where we have `gperftools`
               platforms=filter(p -> !Sys.iswindows(p) && !(Sys.islinux(p) && arch(p) == "aarch64" && libc(p) == "musl"), platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
