using BinaryBuilder

name = "LibOSXUnwind"
version = v"0.0.5"

# Collection of sources required to build libffi
sources = [
    "https://github.com/JuliaLang/libosxunwind/archive/v$(version).tar.gz" =>
    "4ba7b3e24988053870d811afdff58ff103929e7531f156e663f3cf25416c9f46",
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

# When all you have is a hammer...
make -j${nproc} "${FLAGS[@]}"

# Manual installation as the osxunwind `Makefile` doesnt' even know how to do this
mkdir -p ${prefix}/lib
cp libosxunwind.dylib ${prefix}/lib
cp libosxunwind.a ${prefix}/lib
cp -R include ${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if isa(p, MacOS)]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libosxunwind", :libosxunwind)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

