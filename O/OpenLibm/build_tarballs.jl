using BinaryBuilder

name = "OpenLibm"
version = v"0.7.0"
sources = [
    "https://github.com/JuliaMath/openlibm/archive/v$(version).tar.gz" =>
    "1699f773198018b55b12631db9c1801fe3ed191e618a1ee1be743f4570ae06a3",
]

script = raw"""
# Enter the funzone
cd ${WORKSPACE}/srcdir/OpenLibm

# Install into output
flags=("prefix=${libdir}")

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

install_license ${WORKSPACE}/srcdir/OpenLibm/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()

products = [
    LibraryProduct("libopenlibm", :libopenlibm)
]

dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
