# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "satsuma"
version = v"0.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/markusa4/satsuma", "be6beeb6d2538aa133b1f6b7cad84655cda950bb"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/satsuma

for f in $WORKSPACE/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

cp $WORKSPACE/srcdir/tsl/* tsl/

cmake .
make satsuma
install satsuma $bindir
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("satsuma", :satsuma)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("boost_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
  julia_compat="1.6", preferred_gcc_version=v"12")
