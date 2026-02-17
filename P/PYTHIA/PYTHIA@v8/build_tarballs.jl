# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PYTHIA"
version = v"8.312.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://pythia.org/download/pythia83/pythia8312.tgz",
                  "bad98e2967b687046c4568c9091d630a0c31b628745c021a994aba4d1d50f8ea"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pythia*/
./configure --prefix=${prefix} --enable-shared --enable-64bit
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude = p->libc(p) == "musl" || os(p) == "freebsd" || os(p) == "windows") |> expand_cxxstring_abis

# The products that we will ensure are always built
products = [
    LibraryProduct("libpythia8", :libpythia8)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               preferred_gcc_version=v"8", julia_compat="1.6")
