using BinaryBuilder

name = "xsum"
version = v"3.0"

# Collection of sources required to build Xsum
sources = [
    GitSource("https://gitlab.com/radfordneal/xsum.git",
              "b766b3e104cdbd6769c8df033fb430700fce32dd"), # stable-version-3 (2024-11-13)
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xsum
mkdir -p ${libdir}
if [[ $target == i686-* ]]; then
    xsumfpmath="-mfpmath=sse"
fi
${CC} -shared -fPIC -O3 -std=c99 ${xsumfpmath} -fno-inline-functions -o ${libdir}/libxsum.${dlext} xsum.c
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true) # build on all supported platforms

# The products that we will ensure are always built
products = [
    LibraryProduct("libxsum", :libxsum),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
