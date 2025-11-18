# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AppBundlerUtils"
version = v"0.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/PeaceFounder/AppBundler.jl.git", "776473409906752c12dbc0c80bcb6c110f626f67")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/AppBundler.jl/utils

$CC -o macos_launcher macos_launcher.c

install_license $WORKSPACE/srcdir/AppBundler.jl/LICENSE
install -Dvm 755 "macos_launcher" "${bindir}/macos_launcher"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=!Sys.isapple)

# The products that we will ensure are always built
products = [
    ExecutableProduct("macos_launcher", :macos_launcher)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
