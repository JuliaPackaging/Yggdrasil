# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DBCtoDBF"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lego-yaw/DBCtoDBF.git", "293dda7b582dfb4a7ec4ecbd143cc99fa8425610")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd DBCtoDBF/
mkdir -p ${prefix}/share/licenses/
mv LICENSE ${prefix}/share/licenses/
cd SRC/
make
mkdir -p ${prefix}/bin/
mv dbc2dbf ${prefix}/bin/
make test
make clean
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("dbc2dbf", :dbctodbf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
