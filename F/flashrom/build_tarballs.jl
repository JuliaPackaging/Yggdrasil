# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Base.BinaryPlatforms

name = "flashrom"
version = v"1.2.900"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flashrom/flashrom.git",
              "22e9313d908ce376be6686ebeb3f77828ea70c2e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/flashrom/

FLAGS=(
    CONFIG_INTERNAL=yes
    PREFIX=${prefix}
)

make ${FLAGS[@]} -j${nproc}
make ${FLAGS[@]} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(Sys.islinux, supported_platforms())

# ppc64le kernel headers might be broken, disable for now
platforms = filter(p -> arch(p) != "powerpc64le", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("flashrom", :flashrom, "sbin"),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("pciutils_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
