# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SentencePiece"
version = v"0.1.99"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/sentencepiece",
              "3863f7648e5d8edb571ac592f3ac4f5f0695275a"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sentencepiece*

# There is no reason for not building the shared libraries on Windows.
atomic_patch -p1 ../patches/build_shared_library_windows.patch

mkdir build && cd build/

cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      ..
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", preferred_gcc_version=v"8")
