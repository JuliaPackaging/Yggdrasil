# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libinchi"
version = v"1.6.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mojaie/libinchi.git", "81abc8b6e19c77a67ddee854f22f5c8f601ebe69")
]

# Bash recipe for building across all platforms
script = raw"""
install_license $WORKSPACE/srcdir/libinchi/LICENCE.pdf
cd $WORKSPACE/srcdir/libinchi
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
if [[ "${target}" == *-mingw* ]]; then
    mkdir -p "${libdir}"
    cp "libinchi.${dlext}" "${libdir}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libinchi", :libinchi)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
