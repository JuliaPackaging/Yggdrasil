# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sox"
version = v"14.4.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://sourceforge.net/projects/sox/files/sox/$(version)/sox-$(version).tar.bz2",
                  "81a6956d4330e75b5827316e44ae381e6f1e8928003c6aa45896da9041ea149c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sox*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Musl is unsupported
filter!(p -> libc(p) != "musl", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("sox", :sox)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
