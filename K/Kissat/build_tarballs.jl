# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Kissat"
version = v"5.8.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/arminbiere/kissat.git", "abfa45fb782fa3b7c6e2eb6b939febe74d7270b7"),
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/kissat
./configure -shared
make
mkdir -p ${libdir} ${bindir}
cp build/kissat${exeext} ${bindir}/.
cp build/libkissat.so "$libdir/libkissat.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# The products that we will ensure are always built
products = Product[
    ExecutableProduct("kissat", :kissat),
    LibraryProduct("libkissat", :libkissat)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
