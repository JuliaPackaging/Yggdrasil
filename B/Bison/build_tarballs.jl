# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Bison"
version = v"3.5.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/bison/bison-3.5.2.tar.xz", "24e273db9eb6da8bbb6f0648284d0724a5cbd6268a163db402f961350a4e50dd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bison-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# Disable windows for now
platforms = filter(p -> !isa(p, Windows), supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("bison", :bison_exe)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
