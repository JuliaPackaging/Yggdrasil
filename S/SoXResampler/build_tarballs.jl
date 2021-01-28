# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoXResampler"
version = v"0.1.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://pilotfiber.dl.sourceforge.net/project/soxr/soxr-$(version)-Source.tar.xz", "b111c15fdc8c029989330ff559184198c161100a59312f5dc19ddeb9b5a15889")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
apk add libgomp
cd soxr-*
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsoxr", :libsoxr),
    LibraryProduct("libsoxr-lsr", :libsoxr_lsr)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenMPI_jll", uuid="fe0851c0-eecd-5654-98d4-656369965a5c"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
