# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Unicorn"
version = v"1.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/oblivia-simplex/unicorn.git", "cda971566980d3a051a730f63019e74eeeb44703")
]

# Bash recipe for building across all platforms
script = raw"""
ln -s /usr/bin/make /usr/bin/gmake
cd ${WORKSPACE}/srcdir/unicorn
make -j $(nproc)
make PREFIX=${prefix} install
install_license COPYING*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(!Sys.iswindows, supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libunicorn", :libunicorn)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
