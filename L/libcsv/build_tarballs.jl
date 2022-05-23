# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libcsv"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/rgamble/libcsv.git", "6e750805f54f81a26470486d6ed79efaf7d13805")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libcsv/
autoreconf -fiv
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    FLAGS+=(LDFLAGS="-no-undefined")
fi
make -j${nproc} "${FLAGS[@]}"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcsv", :libcsv)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
