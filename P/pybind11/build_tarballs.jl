using BinaryBuilder

name = "pybind11"
version = v"2.5.0"

sources = [
    ArchiveSource(
        "https://github.com/pybind/pybind11/archive/v$(version).tar.gz",
        "97504db65640570f32d3fdf701c25a340c8643037c3b69aec469c10c93dc8504"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pybind11-*
mkdir build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
    -DPYBIND11_PYTHON_VERSION=3.8 \
    -DPYBIND11_TEST=OFF
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# No products: pybind11 is a pure header library
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Python_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
