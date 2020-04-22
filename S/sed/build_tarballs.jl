# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sed"
version = v"4.8.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/sed/sed-4.8.tar.xz", "f79b0cfea71b37a8eeec8490db6c5f7ae7719c35587f21edb0617f370eeff633")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sed-4.8/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc} SUBDIRS="po ."
make install SUBDIRS="po ."
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("sed", :sed)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
