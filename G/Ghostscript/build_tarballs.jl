# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Ghostscript"
version = v"9.52"

# Collection of sources required to build
sources = [
    GitSource(
        "git://git.ghostscript.com/ghostpdl.git", # URL
        "e49830f8efdbc3a9f4e8acaf708b68a742f515aa" # commit hash
    ),
]

# Bash recipe for building across all platforms
script = raw"""
# initial setup
cd $WORKSPACE/srcdir/ghostpdl*

# configure the Makefiles
./configure --prefix=$prefix --host=${target}

# create the binaries
make -j${nproc}

# install to prefixes
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

products = Product[]

dependencies = Dependency[
    Dependency("Libtiff_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
