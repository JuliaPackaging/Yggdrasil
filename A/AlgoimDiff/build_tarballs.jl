# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AlgoimDiff"
version = v"1.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jehicken/algoim.git", 
        "5528fe12c6449d85dcf7960e48ed6e165bfd185b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/algoim/algoim
export CXXFLAGS="-I${includedir}/julia -llapacke -llapack -std=c++17 -fpic"
$CXX $CXXFLAGS -c cutquad.cpp
$CXX -shared -o "${libdir}/libcutquad.${dlext}" cutquad.o -lopenblas
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;
    exclude=p->!Sys.islinux(p) || (libc(p) == "musl" && arch(p) == "i686")
)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcutquad", :libcutquad)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll", uuid="5ad3ddd2-0711-543a-b040-befd59781bbf"))
    Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7"))
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")
