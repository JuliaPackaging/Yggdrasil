using BinaryBuilder

name = "Openlibm"
version = v"0.6.0"
sources = [
    "https://github.com/JuliaMath/openlibm/archive/v$(version).tar.gz" =>
    "d45439093d1fd15e2ac3acf69955e462401c7a160d3330256cb4a86c51bdae28",
]

script = raw"""
# Enter the funzone
cd ${WORKSPACE}/srcdir/openlibm-*

# Install into output
flags=("prefix=${prefix}")

# Build ARCH from ${target}
flags+=("ARCH=${target%-*-*}")

# Openlibm build system doesn't recognize our windows cross compilers properly
if [[ ${target} == *mingw* ]]; then
    flags+=("OS=WINNT")
fi

# Add `CC` override, since Openlibm seems to think it knows best:
flags+=("CC=$CC")

# Build the library
make "${flags[@]}" -j${nproc}

# Install the library
make "${flags[@]}" install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()
platforms = expand_gcc_versions(platforms)

products = prefix -> [
    LibraryProduct(prefix, "libopenlibm", :libopenlibm)
]

dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
