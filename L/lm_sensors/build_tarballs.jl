# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "lm_Sensors"
version = v"3.5.0"

# Collection of sources required to build lm_sensors
sources = [
    "https://github.com/lm-sensors/lm-sensors/archive/V$(version.major)-$(version.minor)-$(version.patch).tar.gz" =>
    "f671c1d63a4cd8581b3a4a775fd7864a740b15ad046fe92038bcff5c5134d7e0",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lm-sensors-*/
make -j${nproc} PREFIX=${prefix}
make install PREFIX=${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Linux]

# The products that we will ensure are always built
products = [
    LibraryProduct("libsensors", :libsensors),
    ExecutableProduct("sensors", :sensors),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
