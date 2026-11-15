# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "spectra"
version = v"1.2"

# Collection of sources required to complete build
sources = [
    # ArchiveSource("https://github.com/yixuan/spectra/archive/refs/tags/v$(version).tar.gz", "45228b7d77b916b5384245eb13aa24bc994f3b0375013a8ba6b85adfd2dafd67")
     GitSource("https://github.com/yixuan/spectra.git", "6841bcbacaa0f0a8446210314e682057a084be4e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/spectra
mkdir build && cd build/

cmake .. \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
#header only, so no products
products = Product[]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
