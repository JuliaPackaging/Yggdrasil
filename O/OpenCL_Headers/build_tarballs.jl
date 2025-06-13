# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "OpenCL_Headers"
version = v"2025.05.07"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/KhronosGroup/OpenCL-Headers.git",
              "1ce4f1ce1070fe47d08666001ce2755af92f0c5c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

install_license ./OpenCL-Headers/LICENSE

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -S ./OpenCL-Headers -B ./OpenCL-Headers/build
cmake --build ./OpenCL-Headers/build --target install -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/CL/cl.h", :cl_h)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"6.1.0")
