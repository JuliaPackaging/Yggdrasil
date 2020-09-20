# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gh_cli"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cli/cli.git", "b2e36a0979a06b94bf364552a856c166cd415234"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cli/
# Use newer termenv to work around issue while building for FreeBSD:
# https://github.com/muesli/termenv/issues/17
atomic_patch -p1 ../patches/use-termenv-v0.7.2.patch
make
mkdir ${bindir}
mv ./bin/gh ${bindir}/gh${exeext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("gh", :gh)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:go, :c])
