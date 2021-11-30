# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Kissat"
version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/arminbiere/kissat.git", "00a3a338e3433b54478efb0f7be0a694b01f0eb9"),
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
platforms = supported_platforms(; exclude=Sys.iswindows, experimental=true)
# The products that we will ensure are always built
products = [
    ExecutableProduct("kissat", :kissat),
    LibraryProduct("libkissat", :libkissat)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
