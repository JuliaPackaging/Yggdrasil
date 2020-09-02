using BinaryBuilder

name = "OpenLibm"
version = v"0.7.0"
sources = [
    GitSource("https://github.com/JuliaMath/openlibm.git",
              "0e414577457d6456ef86f4f122bcaf9894a2685e"),
]

script = raw"""
# Enter the funzone
cd ${WORKSPACE}/srcdir/openlibm*

# Install into output
flags=("prefix=${prefix}")

# Build ARCH from ${target}
flags+=("ARCH=${target%-*-*}")

# OpenLibm build system doesn't recognize our windows cross compilers properly
if [[ ${target} == *mingw* ]]; then
    flags+=("OS=WINNT")
fi

# Add `CC` override, since OpenLibm seems to think it knows best:
flags+=("CC=$CC")

# Build the library
make "${flags[@]}" -j${nproc}

# Install the library
make "${flags[@]}" install

install_license ${WORKSPACE}/srcdir/openlibm-*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()

products = [
    LibraryProduct("libopenlibm", :libopenlibm),
]

dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
