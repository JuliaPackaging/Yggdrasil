# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PicoHTTPParser"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/h2o/picohttpparser.git", "f8326098f63eefabfa2b6ec595d90e9ed5ed958a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cat > CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.10)
project(picohttpparser C)

add_library(picohttpparser SHARED picohttpparser/picohttpparser.c)

install(TARGETS picohttpparser
        LIBRARY DESTINATION $libdir
        ARCHIVE DESTINATION $libdir
        RUNTIME DESTINATION $bindir)
EOF

cmake -B build      -DCMAKE_INSTALL_PREFIX=${prefix}      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}      -DCMAKE_BUILD_TYPE=Release      -S .
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpicohttpparser", :libpicohttpparser)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
