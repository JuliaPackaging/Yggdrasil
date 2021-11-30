# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libnabo"
version = v"1.0.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ethz-asl/libnabo/archive/refs/tags/$(version).tar.gz", "817f43ba77668a7fab2834e78f0a9ff80e294d69c9818142084a32040547d10a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libnabo-*
mkdir build && cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DSHARED_LIBS=ON

make -j${nproc}
make install

install_license ../debian/copyright

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental = true))


# The products that we will ensure are always built
products = [
    LibraryProduct("libnabo", :libnabo)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
