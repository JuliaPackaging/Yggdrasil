using BinaryBuilder

name = "OpenLibm"
version = v"0.7.1"
sources = [
    ArchiveSource("https://github.com/JuliaMath/openlibm/archive/v$(version).tar.gz",
                  "d4b252b71c74571fe5b39d42dee03ccca4bb238827e6a2c9ba108dbca2d3e879"),
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

install_license ./LICENSE.md
"""

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms(;experimental=true)

products = [
    LibraryProduct("libopenlibm", :libopenlibm),
]

dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; lock_microarchitecture=false)
