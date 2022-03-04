# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsixel"
version = v"1.8.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/saitoha/libsixel.git", "5db717dfef6fa327cd4025e7352550f63d20699c"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsixel/

# This patch fixes https://github.com/johnnychen94/Sixel.jl/issues/5
if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ../patches/01-libsixel-win32.patch
fi

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --includedir=$WORKSPACE/destdir/include \
    --libdir=$WORKSPACE/destdir/lib \
    --enable-python=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsixel", :libsixel)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
