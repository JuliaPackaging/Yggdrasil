# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PDFHighlights"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
	GitSource("https://github.com/paveloom-j/PDFHighlights.jl.git", "327d2f73aafbda615101dc3e7b6a296de491dee8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/PDFHighlights.jl/deps/

CC="gcc"
LIB_NAME="PDFHighlightsWrapper"
OBJECTS=(get_author_title get_lines_comments_pages)

OBJECTS_O=()
for index in ${!OBJECTS[@]}; do
    OBJECTS_O[${index}]=${OBJECTS[${index}]}.o
done

INCLUDE_FLAGS="`pkg-config --cflags poppler-glib`"
LINK_FLAGS="-lgio-2.0 `pkg-config --libs poppler-glib`"

if [[ "${target}" == *-darwin* ]]; then
    OBJ_FLAGS="-std=c99 -O3 -fPIC"
    LIB_FLAGS="-shared"
elif [[ "${target}" == *-mingw* ]]; then
    OBJ_FLAGS="-std=c99 -O3"
    LIB_FLAGS="-shared"
    LINK_FLAGS="${LINK_FLAGS} -Wl,--out-implib,${prefix}/lib/${LIB_NAME}.dll.a"
else
    OBJ_FLAGS="-std=c99 -O3 -fPIC"
    LIB_FLAGS="-shared -Wl,--no-undefined"
fi

for file in ${OBJECTS[@]}; do
    ${CC} ${OBJ_FLAGS} -c ${file}.c -o ${file}.o ${INCLUDE_FLAGS}
done

${CC} ${LIB_FLAGS} -o ${libdir}/${LIB_NAME}.${dlext} ${OBJECTS_O[@]} ${LINK_FLAGS}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("PDFHighlightsWrapper", :PDFHighlightsWrapper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Poppler_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5")
