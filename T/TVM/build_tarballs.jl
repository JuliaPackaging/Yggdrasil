# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "TVM"
version = v"0.22.0"

sources = [
    GitSource("https://github.com/apache/tvm.git",
        "9dbf3f22ff6f44962472f9af310fda368ca85ef2"),
]

# Bash recipe for building across all platforms
script = raw"""
# Next, enter TVM and start building it
cd $WORKSPACE/srcdir/tvm
git submodule update --init --recursive
cmake -B ../../build -DCMAKE_INSTALL_PREFIX="${prefix}" \
         -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
         -DCMAKE_BUILD_TYPE=Release \
         -DTVM_BUILD_PYTHON_MODULE=OFF
cmake --build ../../build --parallel $(nproc)
cmake --install ../../build
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct("libtvm", :libtvm),
    LibraryProduct("libtvm_runtime", :libtvm_runtime),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, preferred_gcc_version=v"8", julia_compat="1.6")
