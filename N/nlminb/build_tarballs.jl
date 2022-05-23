using BinaryBuilder

name = "nlminb"
version = v"0.1.1"

# Collection of sources required to build NLopt
sources = [
    GitSource("https://github.com/eco-hydro/nlminb.f.git",
              "4d8d42e4b03629cacf4d7531b4d496f44261d18f"), # v0.1.1
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nlminb.f

## compile by hand
if [[ "${proc_family}" == "intel" ]]; then
    FLAGS="-mfpmath=sse -msse2 -mstackrealign"
fi

CFLAGS="-fPIC -DNDEBUG  -Iinclude -O2 -Wall -std=gnu99 ${FLAGS}" \
    FFLAGS="-fPIC -fno-optimize-sibling-calls -O2 ${FLAGS}" \
    target=${libdir}/libnlminb.${dlext} make
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libnlminb", :libnlminb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
