# Build script for stb: C++ header-only single-file utilities.
# This is basically just a dummy package that installs header files, and makes
# them available for other packages.

using BinaryBuilder


name = "stb"
# stb doesn't ever do releases, so the best we can do is stick to a specific git
# revision...
version = v"0.0.20221025"
sources = [
    ArchiveSource("https://github.com/nothings/stb/archive/8b5f1f37b5b75829fc72d38e7b5d4bcbf8a26d55.zip",
                  "93a16ee3e866e719feec459f6f132cce932c5ec751eb38e3ec1975f911353d2e")
]

script = raw"""
cd ${WORKSPACE}/srcdir/stb*/
mkdir -p "${includedir}"
cp -vr *.h "${includedir}/."
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = [AnyPlatform()]

# Cereal produces nothing, since it is header-only.
products = Product[]

# Dependencies that must be installed before this package can be built.
dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", julia_compat="1.7")
