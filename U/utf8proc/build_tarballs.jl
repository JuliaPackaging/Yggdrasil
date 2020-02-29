using BinaryBuilder

name = "utf8proc"
version = v"2.4.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/JuliaStrings/utf8proc/archive/v$(version).tar.gz",
                  "b2e5d547c1d94762a6d03a7e05cea46092aab68636460ff8648f1295e2cdfbd7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/utf8proc-*

if [[ "${target}" == *-mingw* ]]; then
    make -j${nproc} libutf8proc.a
    mkdir -p ${libdir} ${prefix}/include
    cp utf8proc.h ${prefix}/include/
    ar x libutf8proc.a
    cc -shared -o "${libdir}/libutf8proc.${dlext}" *.o
else
    make -j${nproc}
    make install prefix=${prefix} libdir=${libdir}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libutf8proc", :libutf8proc),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
