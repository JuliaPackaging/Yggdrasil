# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libqasm"
version = v"0.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/QuTech-Delft/libqasm.git", "1f317077e2f2462cafec8385666d6e996340d2e8")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p $WORKSPACE/srcdir/libqasm/build
cd $WORKSPACE/srcdir/libqasm/build/
git submodule init
git submodule update
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DLIBQASM_COMPAT=ON -DBUILD_SHARED_LIBS=ON -DLIBQASM_BUILD_PYTHON=OFF ..
export PATH=$PATH:/workspace/srcdir/libqasm/build/src/cqasm/tree-gen/:/workspace/srcdir/libqasm/build/src/cqasm/func-gen/
make -j
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcqasm", :libcqasm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="Bison_jll", uuid="0f48145f-aea8-549d-8864-7f251ac1e6d0"))
    HostBuildDependency(PackageSpec(name="flex_jll", uuid="48a596b8-cc7a-5e48-b182-65f75e8595d0"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5.2.0")
