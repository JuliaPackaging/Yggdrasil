# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "dlfcn_win32"
version = v"1.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dlfcn-win32/dlfcn-win32.git", "3b52e651f385df00045dd8966407fd9de57fc94b"),
]

dependencies = Dependency[
]

# Bash recipe for building across all platforms
script = raw"""
cd dlfcn-win32

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.iswindows(p), supported_platforms())

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libdl", :libdl)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
