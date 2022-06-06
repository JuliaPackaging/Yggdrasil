# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SassC"
version = v"3.6.2"

# Collection of sources required to build SassBuilder
sources = [
    GitSource("https://github.com/sass/sassc.git", "66f0ef37e7f0ad3a65d2f481eff09d09408f42d0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sassc*
export CPPFLAGS="-I${includedir}"
autoreconf --force --install
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("sassc", :sassc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libsass_jll"; compat="3.6.4"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
