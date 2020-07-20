using BinaryBuilder

name = "LibOSXUnwind"
version = v"0.0.6"

# Collection of sources required to build libosxunwind
sources = [
    ArchiveSource("https://github.com/JuliaLang/libosxunwind/archive/v$(version).tar.gz",
                  "61f88a1fa8f5ba7492ffed7c7049ed7d3d77841ac633a4894a23dcf86203e7d8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libosxunwind*/

EXTRA_CFLAGS="-ggdb3 -O2"

FLAGS=(
    CC="$CC"
    CXX="$CXX"
    CFLAGS="${CFLAGS} -ggdb3 -O2"
    CXXFLAGS="${CXXFLAGS} -ggdb3 -O2"
    PREFIX="${prefix}"
)

# When all you have is a hammer...
make -j${nproc} "${FLAGS[@]}"

# Manual installation as the osxunwind `Makefile` doesnt' even know how to do this
mkdir -p ${libdir}
cp libosxunwind.dylib ${libdir}/
cp libosxunwind.a ${libdir}/
cp -aR include ${prefix}/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> isa(p, MacOS), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libosxunwind", :libosxunwind),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
