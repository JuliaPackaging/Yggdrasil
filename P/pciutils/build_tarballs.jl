# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "pciutils"
version = v"3.7.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pciutils/pciutils.git",
              "864aecdea9c7db626856d8d452f6c784316a878c")
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
    -j${nproc}
)
make ${FLAGS[@]} install
make ${FLAGS[@]} install-lib
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> !Sys.iswindows(p) && !Sys.isapple(p), supported_platforms(;experimental=true))

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("lspci", :lspci),
    ExecutableProduct("setpci", :setpci),
    LibraryProduct("libpci", :libpci)
]

# Build the tarballs, and possibly a `build.jl` as well.
# gcc7 constraint from boost
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
