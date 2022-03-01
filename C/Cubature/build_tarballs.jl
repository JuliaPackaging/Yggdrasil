using BinaryBuilder

name="Cubature"
version=v"1.0.5" # <-- This version is a lie, we need to bump it to build for experimental platforms

# Collection of sources required to build Cubature
sources = [
    GitSource("https://github.com/stevengj/cubature.git",
              "03d4af5f3ec30d2400e129bdb17739808c92dfd9"), # v1.0.4
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cubature*
mkdir -p ${libdir}
${CC} ${LDFLAGS} -shared -fPIC -O3 hcubature.c pcubature.c -o ${libdir}/libcubature.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcubature", :libcubature),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
