#
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DBCtoDBF"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lego-yaw/DBCtoDBF.git", "b5333eb8378b5fae64b5de5f827e4335bade35cf")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/DBCtoDBF/SRC
install_license ../LICENSE
make -j${nproc} CC=${CC}
install -Dvm 755 "dbc2dbf" "${bindir}/dbc2dbf${exeext}"
make test
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("dbc2dbf", :dbc2dbf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
