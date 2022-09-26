# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "KMC"
version = v"3.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/refresh-bio/KMC.git", "13b9b04120e902d158bd0cb87d83b63b742781b9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/KMC/
make kmc kmc_dump kmc_tools
mkdir -p ${bindir}
cp bin/kmc${exeext} bin/kmc_dump${exeext} bin/kmc_tools${exeext} ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("kmc_dump", :kmc_dump),
    ExecutableProduct("kmc_tools", :kmc_tools),
    ExecutableProduct("kmc", :kmc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
