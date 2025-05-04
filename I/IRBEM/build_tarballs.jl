# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "IRBEM"
version = v"5.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/PRBEM/IRBEM.git", "e7cecb00caf97bb6357f063d2ba1aa76d71a3705")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/IRBEM
if [[ ${target} == *mingw* ]]; then
    make -j${nproc} OS=win64 ENV=gfortran64 all
    make OS=win64 ENV=gfortran64 install
elif [[ ${target} == *apple* ]]; then
    make -j${nproc} OS=osx64 ENV=gfortran64 all
    make OS=osx64 ENV=gfortran64 install
else
    make -j${nproc} OS=linux64 ENV=gfortran64 all
    make OS=linux64 ENV=gfortran64 install
fi
install -Dvm 755 libirbem.so "${libdir}/libirbem.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libirbem", :libirbem)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
