# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cliquer"
version = v"1.21.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://users.aalto.fi/~pat/cliquer/cliquer-1.21.tar.gz", "ff306d27eda82383c0257065e3ffab028415ac9af73bccfdd9c2405b797ed1f1"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cliquer-1.21/
cc -Wall -O3 -fomit-frame-pointer -funroll-loops -shared -fPIC -I. -o "libcliquer.${dlext}" cliquer.c graph.c reorder.c  $WORKSPACE/srcdir/wrappers_for_julia.c
install -Dvm 755 "libcliquer.${dlext}" -t "${libdir}"
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcliquer", :libcliquer)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
