# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "librtlsdr"
version = v"0.6.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/steve-m/librtlsdr.git", "1f0eafe60445339703903af6d8814ffab7e73784")
]

dependencies = [
    Dependency("libusb_jll"; compat="1.0.24")
]

# Bash recipe for building across all platforms
script = raw"""
cd librtlsdr
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p-> arch(p) != "armv6l", supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = Product[
    LibraryProduct("librtlsdr", :librtlsdr)
]

# Build the tarballs, and possibly a `build.jl` as well.
# gcc7 constraint from boost
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
