# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsodium"
# Note: upstream stopped giving version numbers to new releases.  "Releases" are
# commits to the "stable" branch.  Here we just invent new versions numbers
# because we need having different versions.
version = v"1.0.20"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jedisct1/libsodium.git", "d3f4804f4d4e6b5b4610fe377f6ff24e4368ae09"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsodium

./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsodium", :libsodium)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")

# Build trigger: 1
