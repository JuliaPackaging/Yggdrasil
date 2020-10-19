# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LCIO"
version = v"02.15.3"

# Collection of sources required to build LCIO
sources = [
    GitSource("https://github.com/iLCSoft/LCIO.git", "ace40cbdb7501a366658fc737954e8634d105f62"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/LCIO*/
mkdir build && cd build

cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
cmake --build . --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(!Sys.isfreebsd, platforms)
filter!(!Sys.iswindows, platforms)
filter!(p -> arch(p) != "armv7l", platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblcio", :liblcio),
    LibraryProduct("libsio", :libsio)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, preferred_gcc_version=v"7")
