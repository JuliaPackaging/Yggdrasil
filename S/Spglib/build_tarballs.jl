# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Spglib"
version = v"0.2.0"

# Collection of sources required to build SpglibBuilder
sources = [
    "https://github.com/atztogo/spglib/archive/v1.14.1.tar.gz" =>
    "9803b0648d9c2d99377f3e1c4cecf712320488403cd674192ec5cbe956bb3c78",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd spglib-1.14.1/
if [[ ${target} == *-mingw32 ]]; then
    sed -i -e 's/LIBRARY/RUNTIME/' CMakeLists.txt
fi
mkdir _build
cd _build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain \
      ../
make
make install VERBOSE=1
"""


# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Windows(:i686),
    Windows(:x86_64),
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libsymspg", :libsymspg)
]

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
