# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "xpa"
version = v"2.1.19"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ericmandel/xpa.git", "c0452e139134d6d1677b5e6fda2ad5283c8ba4c7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xpa
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j$(nproc)
if [[ ${target} == *mingw* ]]; then
    # Target Windows specifically until https://github.com/ericmandel/xpa/pull/11 is merged and released
    make EXE='' install -j$(nproc)
else
    make install
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("xpamb", :xpamb),
    ExecutableProduct("xpaget", :xpaget),
    ExecutableProduct("xpainfo", :xpainfo),
    ExecutableProduct("xpans", :xpans),
    ExecutableProduct("xpaset", :xpaset),
    ExecutableProduct("xpaaccess", :xpaaccess)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
