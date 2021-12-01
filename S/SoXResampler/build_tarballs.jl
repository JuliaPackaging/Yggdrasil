# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoXResampler"
version = v"0.1.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://sourceforge.net/code-snapshots/git/s/so/soxr/code.git/soxr-code-945b592b70470e29f917f4de89b4281fbbd540c0.zip", 
        "b797a5d23078be234e520af1041b5e11b49864696d56f0d0b022a0349d1e8d1b"
    )
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/soxr-code-*
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
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
