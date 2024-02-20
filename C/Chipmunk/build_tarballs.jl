# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Chipmunk"
version = v"7.0.3"

# Collection of sources required to complete build
# This is a few commits since the 7.0.3 tag to include some fixes. 
# Keeping the same version number since that's included in the build file. 
sources = [
    GitSource("https://github.com/slembcke/Chipmunk2D.git", "7d10641155864bcf0e7f4c7cf1f0327ec7c1d90d"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd Chipmunk2D/
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_DEMOS=OFF -DBUILD_STATIC=OFF -DINSTALL_STATIC=OFF -DBUILD_SHARED=ON ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libchipmunk", :libchipmunk)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
