# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ffts"
version = v"0.9.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/anthonix/ffts.git", "fe86885ecafd0d16eb122f3212403d1d5a86e24e"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd ffts/
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DENABLE_SHARED=ON ..
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# filter failing ARM targets
filter!(p -> arch(p) ≠ "armv7l", platforms)
filter!(p -> arch(p) ≠ "armv6l", platforms)
filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libffts", :libffts)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
