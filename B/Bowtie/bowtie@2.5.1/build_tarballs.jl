# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
include("../common.jl")

version = v"2.5.1"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/BenLangmead/bowtie2.git",
        "04a2ecd521a71f2cb567c51c988bdc225fb41658",
    ),
]

# Bash recipe for building across all platforms
# TODO: Figure out how to include libsais, Zstd in the build process
# TODO: Figure out Windows builds (build system for some reason does not handle missing sys/mman header)
script = raw"""
cd $WORKSPACE/srcdir/bowtie*
install_license LICENSE
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DZLIB_INCLUDE_DIR=${includedir} \
      -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc} SANITIZER_FLAGS="-fsanitize=undefined"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = Platform[
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "freebsd"),
    Platform("x86_64", "linux"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("bowtie2", :bowtie2),
    ExecutableProduct("bowtie2-align-l", :bowtie2_align_l),
    ExecutableProduct("bowtie2-align-s", :bowtie2_align_s),
    ExecutableProduct("bowtie2-build", :bowtie2_build),
    ExecutableProduct("bowtie2-build-l", :bowtie2_build_l),
    ExecutableProduct("bowtie2-build-l", :bowtie2_build_l),
    ExecutableProduct("bowtie2-build-s", :bowtie2_build_s),
    ExecutableProduct("bowtie2-inspect", :bowtie2_inspect),
    ExecutableProduct("bowtie2-inspect-l", :bowtie2_inspect_l),
    ExecutableProduct("bowtie2-inspect-s", :bowtie2_inspect_s),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(
        PackageSpec(; name = "Zlib_jll", uuid = "83775a58-1f1d-513f-b197-d71354ab007a");
        compat = "1.2.13",
    ),
    BuildDependency("SIMDe_jll"),
]

build_bowtie(version, sources, script, platforms, products, dependencies)
