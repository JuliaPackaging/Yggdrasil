# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "pciutils"
version = v"3.12.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pciutils/pciutils.git",
              "cb00a99b8d32d04b4647c32811ba9c86446d36ae")
]

dependencies = Dependency[
]

# Bash recipe for building across all platforms
script = raw"""
cd pciutils
FLAGS=(
    PREFIX=${prefix}
    SHARED=yes
    SBINDIR=${bindir}
    CFLAGS='-std=gnu99 -fPIC -O2 -Wall'
    -j${nproc}
)
make "${FLAGS[@]}" install
make "${FLAGS[@]}" install-lib
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> !Sys.iswindows(p) && !Sys.isapple(p), supported_platforms())

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("lspci", :lspci),
    ExecutableProduct("setpci", :setpci),
    LibraryProduct("libpci", :libpci)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
