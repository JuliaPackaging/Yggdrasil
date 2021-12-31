# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Atomsk"
version = v"0.11.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pierrehirel/atomsk.git", "3333858281e0ebd6279825b83ab871cf4d050a8d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/atomsk/src/
mkdir -p ${bindir}
# The makefile doesn't handle parallel builds
make atomsk BIN="atomsk${exeext}"
make install INSTPATH=${prefix} BIN="atomsk${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("atomsk", :atomsk)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
