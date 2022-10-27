# Build script for cereal: C++ header-only library for serialization.
# This is basically just a dummy package that installs header files, and makes
# them available for other packages.

using BinaryBuilder


name = "cereal"
version = v"1.3.2"
sources = [
    ArchiveSource("https://github.com/USCILab/cereal/archive/refs/tags/v$(version).tar.gz",
                  "16a7ad9b31ba5880dac55d62b5d6f243c3ebc8d46a3514149e56b5e7ea81f85f")
]

script = raw"""
cd ${WORKSPACE}/srcdir/cereal-*/
mkdir -p "${includedir}"
cp -vr include/* "${includedir}/."
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = [AnyPlatform()]

# Cereal produces nothing, since it is header-only.
products = Product[]

# Dependencies that must be installed before this package can be built.
dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", julia_compat="1.7")
