# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cfastcdr"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
  GitSource("https://github.com/twadleigh/cfastcdr.git", "95fbe6f293380cab3945fd2b92840aa2e44a133c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cfastcdr
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
#platforms = [HostPlatform()]

# The products that we will ensure are always built
products = Product[
  LibraryProduct("libcfastcdr", :libcfastcdr_1)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
  Dependency(PackageSpec(name="FastCDR_jll", uuid="4c445503-5c2d-5ebd-97f6-9e823778a91e"), v"1.0.27"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
