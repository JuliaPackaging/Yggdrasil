using BinaryBuilder

name = "dSFMT"
version = v"2.2.5"

# Collection of sources required to build dSFMT
sources = [
    GitSource("https://github.com/MersenneTwister-Lab/dSFMT.git",
              "6929b76f2ab07e6302f8daece28045d5bec6ff5c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/dSFMT

FLAGS=(
    -O3 -finline-functions -fomit-frame-pointer -fno-strict-aliasing -Wmissing-prototypes -Wall -std=c99
    -DNDEBUG -DDSFMT_MEXP=19937
    -fPIC -shared -DDSFMT_SHLIB -DDSFMT_DO_NOT_USE_OLD_NAMES
)

if [[ ${target} == x86_64* ]]; then
    FLAGS+=(-msse2 -DHAVE_SSE2)
fi

mkdir -p "${libdir}"
${CC} ${FLAGS[@]} ${CFLAGS} ${CPPFLAGS} ${LDFLAGS} -o "${libdir}/libdSFMT.${dlext}" dSFMT.c
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libdSFMT", :libdSFMT),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
