# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libgsd"
version = v"3.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/glotzerlab/gsd.git", "ad2417d0dbc455d1fb5aab525a919b36bc7f0851")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/gsd/
mkdir -p "${libdir}"
install -Dv -m644 ./gsd/gsd.h ${includedir}/gsd.h
${CC} -std=c99 -fPIC gsd/gsd.c -shared -o "${libdir}/libgsd.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Windows cant be build since the source code implicitly requires commands from unistd.h which only exist for unix and unix-like systems
platforms = filter!(!Sys.iswindows, platforms)


# The products that we will ensure are always built
products = [
    FileProduct("include/gsd.h", :gsd_h), 
    LibraryProduct("libgsd", :libgsd)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
