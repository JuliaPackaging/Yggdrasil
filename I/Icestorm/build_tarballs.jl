# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Icestorm"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/YosysHQ/icestorm.git", "c495861c19bd0976c88d4964f912abe76f3901c3")
]

dependencies = Dependency[
]

# Bash recipe for building across all platforms
script = raw"""
cd icestorm
make PREFIX=${prefix} ICEPROG=0 -j${nproc}
make install PREFIX=${prefix} ICEPROG=0
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> !Sys.iswindows(p), supported_platforms(;experimental=true))
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("iceunpack", :iceunpack),
    ExecutableProduct("icebox_diff", :icebox_diff),
    ExecutableProduct("icebox_stat", :icebox_stat),
    ExecutableProduct("icebox_colbuf", :icebox_colbuf),
    ExecutableProduct("icebox_maps", :icebox_maps),
    ExecutableProduct("icebox_explain", :icebox_explain),
    ExecutableProduct("icebox_chipdb", :icebox_chipdb),
    ExecutableProduct("icepll", :icepll),
    ExecutableProduct("icebox_html", :icebox_html),
    ExecutableProduct("icemulti", :icemulti),
    ExecutableProduct("icebox_asc2hlc", :icebox_asc2hlc),
    ExecutableProduct("icebox_hlc2asc", :icebox_hlc2asc),
    ExecutableProduct("icebox_vlog", :icebox_vlog),
    ExecutableProduct("icebram", :icebram),
    ExecutableProduct("icepack", :icepack),
    ExecutableProduct("icetime", :icetime)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
