# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "likwid"
version = v"5.2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://ftp.fau.de/pub/likwid/likwid-$(version).tar.gz", "1b8e668da117f24302a344596336eca2c69d2bc2f49fa228ca41ea0688f6cbc2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd likwid-5.2.1/
sed -i 's/PREFIX ?= .*/PREFIX ?= \/workspace\/destdir/' config.mk
sed -i 's/ACCESSMODE = .*/ACCESSMODE = perf_event/' config.mk
sed -i 's/BUILDFREQ = .*/BUILDFREQ = false/' config.mk
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("liblikwid", :liblikwid),
    ExecutableProduct("likwid-lua", :likwid_lua),
    ExecutableProduct("likwid-bench", :likwid_bench)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
