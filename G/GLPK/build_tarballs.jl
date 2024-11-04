using BinaryBuilder, Pkg

name = "GLPK"
version = v"5.0.1" # <-- This is a lie, we're bumping from 5.0 to 5.0.1 to create a Julia v1.6+ release with experimental platforms

# Collection of sources required to build GLPK
sources = [
    ArchiveSource("http://ftpmirror.gnu.org/gnu/glpk/glpk-$(version.major).$(version.minor).tar.gz",
                  "4a1013eebb50f728fc601bdd833b0b2870333c3b3e5a816eeba921d95bec6f15"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glpk*
if [[ ${target} == *mingw* ]]; then
    export CPPFLAGS="-I${prefix}/include -D__WOE__=1"
else
    export CPPFLAGS="-I${prefix}/include"
fi
autoreconf -vi
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE} --with-gmp
make -j${nproc}
make install
"""

# Build for all platforms
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libglpk", :libglpk)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We use GMP_jll v6.2.0 because we're requiring Julia v1.6+
    Dependency("GMP_jll", v"6.2.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Use the same preferred_gcc_version as GMP.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               preferred_gcc_version=v"6", julia_compat="1.6")

# Build trigger: 1
