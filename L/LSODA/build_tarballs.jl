# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LSODA"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sdwfrost/liblsoda.git", "014a16bfa199eaffcf641eafdce8dcc487bfe9d9"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/liblsoda*
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
make -j${nproc} CC=cc
install -Dvm 755 "src/liblsoda.${dlext}" "${libdir}/liblsoda.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblsoda", :liblsoda)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
