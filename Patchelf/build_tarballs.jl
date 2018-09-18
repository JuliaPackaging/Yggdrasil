# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Patchelf"
version = v"2018.05.09"

sources = [
    "https://github.com/NixOS/patchelf.git" =>
    "27ffe8ae871e7a186018d66020ef3f6162c12c69",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/patchelf*/

./bootstrap.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, :glibc)
]

# The products that we will ensure are always built
products(prefix) = Product[
    ExecutableProduct(prefix, "patchelf", :patchelf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

