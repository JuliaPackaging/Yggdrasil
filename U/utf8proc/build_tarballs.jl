using BinaryBuilder

name = "utf8proc"
version = v"2.9.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaStrings/utf8proc.git",
              "34db3f7954e9298e89f42641ac78e0450f80a70d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/utf8proc*

if [[ "${target}" == *-mingw* ]]; then
    make -j${nproc} libutf8proc.a
    mkdir -p ${libdir} ${prefix}/lib ${includedir}
    cp utf8proc.h ${includedir}
    ar x libutf8proc.a
    cc -shared -o "${libdir}/libutf8proc.${dlext}" *.o
    cp libutf8proc.a ${prefix}/lib
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
