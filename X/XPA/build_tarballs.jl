# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "XPA"
version = v"2.1.20"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ericmandel/xpa.git", "923cc1bc7e761424b87049b1a20853eefe921388"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xpa
if [[ "${target}" == *-freebsd* ]]; then
    export CFLAGS=-fPIC
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared=yes
make -j$(nproc)
if [[ ${target} == *mingw* ]]; then
    make mingw-dll
    mkdir -p ${libdir}
    cp libxpa.dll ${libdir}/libxpa.dll
fi
make install
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
    ExecutableProduct("xpaaccess", :xpaaccess),
    LibraryProduct("libxpa", :libxpa)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
