# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CDFpp"
version = v"0.8.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/SciQLop/CDFpp.git", "a46a3437ca543a06e372c6b2156e773a4508165d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CDFpp

# Configure with meson
meson setup build \
    --cross-file=${MESON_TARGET_TOOLCHAIN} \
    --buildtype=release \
    -Ddisable_python_wrapper=true

cd build/
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
# CDFpp is a header-only library, so no LibraryProduct is needed
products = [
    FileProduct("include/cdfpp/cdf.hpp", :cdf_hpp),
    FileProduct("include/cdfpp/cdf-io/cdf-io.hpp", :cdf_io_hpp),
]


# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    clang_use_lld = false, julia_compat = "1.6", preferred_gcc_version = v"7.0.0"
)
