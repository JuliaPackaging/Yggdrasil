# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibYAML"
version = v"0.2.7" #​ <-- This version is a lie, we need to bump it to build for experimental platforms

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://pyyaml.org/download/libyaml/yaml-0.2.5.tar.gz",
                  "c642ae9b75fee120b2d96c712538bd2cf283228d2337df2cf2988e3c02678ef4")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/yaml-*/

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libyaml", "libyaml-0"], :libyaml)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
