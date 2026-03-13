# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Epsteinlib"
version = v"0.5.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/epsteinlib/epsteinlib.git", "de8028eb1c539cd4ef8c5ab229f4398c68577722")
]

# Bash recipe for building across all platforms
script = raw"""
pip install cython
cd $WORKSPACE/srcdir/epsteinlib
meson setup build --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release -Dbuild_python=false
ninja -C build -j${nproc}
ninja -C build install
install_license LICENSES/*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libepstein", :libepstein),
    ExecutableProduct("epsteinlib_c-lattice_sum", :epsteinlib_c_lattice_sum)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", clang_use_lld=false)
