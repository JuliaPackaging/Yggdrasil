# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Graphite2"
version = v"1.3.13"

# Collection of sources required to build Graphite2
sources = [
    ArchiveSource("https://github.com/silnrsi/graphite/releases/download/$(version)/graphite2-$(version).tgz",
                  "dd63e169b0d3cf954b397c122551ab9343e0696fb2045e1b326db0202d875f06"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/graphite2-*/
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix \
         -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
         -DBUILD_SHARED_LIBS=ON \
         -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgraphite2", :libgraphite2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# We require gcc 5+ so that mingw defines __MINGW_INTSAFE_WORKS, which allows `intsafe.h` to actually
# have an effect.  Otherwise, we get a bevvy of errors around `SizeTMult` not being defined.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5")
