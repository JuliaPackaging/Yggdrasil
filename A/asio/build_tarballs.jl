# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "asio"
version = v"1.36.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/chriskohlhoff/asio.git", "231cb29bab30f82712fcd54faaea42424cc6e710"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd asio/asio
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
all_platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libasio", :libasio),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
# GCC v4 is missing `std::align`
build_tarballs(
    ARGS, name, version, sources, script, all_platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"5",
)
