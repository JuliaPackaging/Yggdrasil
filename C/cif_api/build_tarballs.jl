# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Clingo"
version = v"5.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/COMCIFS/cif_api.git", "0000f6cd102b978ba5518ae050deb1b773486eae")
]

# Bash recipe for building across all platforms
script = raw"""
apk add icu-dev
cd $WORKSPACE/srcdir/cif_api
./configure --prefix=$prefix --host=${target} --with-sqlite3=${prefix} --with-icu=${prefix}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcif",:libcif)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("SQLite_jll")
    Dependency("ICU_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
