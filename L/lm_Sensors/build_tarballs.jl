# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "lm_Sensors"
version = v"3.5.0"

# Collection of sources required to build lm_sensors
sources = [
    GitSource("https://github.com/lm-sensors/lm-sensors.git",
              "e8afbda10fba571c816abddcb5c8180afc435bba"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lm-sensors*/
make -j${nproc} PREFIX=${prefix}
make install PREFIX=${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=!Sys.islinux)
filter!(p->arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsensors", :libsensors),
    ExecutableProduct("sensors", :sensors),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
