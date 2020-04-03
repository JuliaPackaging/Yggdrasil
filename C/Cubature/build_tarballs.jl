using BinaryBuilder

name="Cubature"
version=v"1.0.3"

# Collection of sources required to build Cubature
sources = [
    GitSource("https://github.com/stevengj/cubature.git",
              "a61dd32094bcf925fbc4a93d02e0f0f147f8b734"), # v1.0.3
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cubature*
mkdir -p ${libdir}
${CC} ${LDFLAGS} -shared -fPIC -O3 hcubature.c pcubature.c -o ${libdir}/libcubature.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcubature", :libcubature),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
