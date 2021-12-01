# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tippecanoe"
version = v"1.36.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mapbox/tippecanoe.git",
                  "97ace997ff2d709fe2e26e2dda909cf4afd458ac"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tippecanoe
make -j${nproc} INCLUDES="-I${includedir} -I." LIBS="-L${libdir}"
mkdir -p $prefix
PREFIX=$prefix make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = filter(
    # Windows outright unsupported;
    # FreeBSD probably needs `#include <sys/statfs.h>` wrapped in an #ifndef upstream
    p -> !(Sys.iswindows(p) || Sys.isfreebsd(p)),
    supported_platforms(),
)

# The products that we will ensure are always built
products = [
    ExecutableProduct("tippecanoe", :tippecanoe),
    ExecutableProduct("tippecanoe-enumerate", :tippecanoe_enumerate),
    ExecutableProduct("tippecanoe-decode", :tippecanoe_decode),
    ExecutableProduct("tippecanoe-json-tool", :tippecanoe_json_tool),
    ExecutableProduct("tile-join", :tile_join),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("SQLite_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
