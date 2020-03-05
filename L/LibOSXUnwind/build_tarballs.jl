using BinaryBuilder

name = "LibOSXUnwind"
version = v"0.0.5"

# Collection of sources required to build libffi
sources = [
    ArchiveSource("https://github.com/JuliaLang/libosxunwind/archive/v$(version).tar.gz",
                  "4ba7b3e24988053870d811afdff58ff103929e7531f156e663f3cf25416c9f46"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libosxunwind*/

EXTRA_CFLAGS="-ggdb3 -O0"

FLAGS=(
    CC="$CC"
    CXX="$CXX"
    CFLAGS="${CFLAGS} -ggdb3 -O0"
    CXXFLAGS="${CXXFLAGS} -ggdb3 -O0"
    # We lie aobut this because Apple version numbers have nothing to do with
    # upstream LLVM version numbers.  Sigh.
    CLANG_MAJOR_VERSION=10
    PREFIX="${prefix}"
)

# Comment out CLANG_MAJOR_VERSION setting, since it is broken in BB due to non-apple clang output
sed -i.bak -e 's/^CLANG_MAJOR_VERSION := .*$//g' Makefile

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
