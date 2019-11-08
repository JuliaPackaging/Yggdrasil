# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Patchelf"
version = v"2019.10.23"

sources = [
    "https://github.com/NixOS/patchelf.git" =>
    "2ba64817ec6f3b714503ea6e6aa8439505bb7393",
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
    Linux(:x86_64; libc=:glibc),
]

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("patchelf", :patchelf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

