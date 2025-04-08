# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoapyLoopback"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaTelecom/SoapyLoopback.git", "2531a7647d2ba1e01c96586eb43b0afc2b946bd6")
]

dependencies = [
    Dependency("soapysdr_jll", v"0.8.1"; compat="0.8")
]

# Bash recipe for building across all platforms
script = raw"""
cd SoapyLoopback
mkdir build
cd build
# This package is only used in testing so we want a Debug build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Debug \
      ..
make -j${nproc}
make install
if [[ "${target}" == *-apple-* ]]; then
    mv ${libdir}/SoapySDR/modules0.8/libsoapyloopback.so  ${libdir}/SoapySDR/modules0.8/libsoapyloopback.dylib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libsoapyloopback", :librtlsdrSupport, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
