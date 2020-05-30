# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "leanprovercommunity"
version = v"3.15.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/leanprover-community/lean.git", "56f8877f1efa22215aca0b82f1c0ce2ff975b9c3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd lean
cd src
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc} bin_lean
mkdir -p "${bindir}"
cp ${WORKSPACE}/srcdir/lean/bin/* "${bindir}"
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("lean", :lean)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
