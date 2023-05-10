# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QhullMiniWrapper"
version = v"1.0.0"

# Collection of sources required to build
sources = [
    DirectorySource("./Wrapper")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/
${CC} -fPIC -shared -o ${libdir}/qhullwrapper.${dlext} qhullwrapper.c -L${libdir} -lqhull_r
"""
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("qhullwrapper", :qhullwrapper)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="Qhull_jll"), compat="8.0.1000")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
