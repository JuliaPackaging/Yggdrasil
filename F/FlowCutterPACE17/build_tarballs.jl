# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FlowCutterPACE17"
version = v"0.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kit-algo/flow-cutter-pace17.git", "fd405a2b003c9a93838e0488728addc0610a769f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/flow-cutter-pace17/
mkdir -p "${bindir}"
c++ -o "${bindir}/flow_cutter_pace17${exeext}" -Wall -std=c++11 -O3 -DNDEBUG src/*.cpp
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("flow_cutter_pace17", :flow_cutter_pace17)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
