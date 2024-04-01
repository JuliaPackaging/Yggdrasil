# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoapyPlutoSDR"
version = v"0.2.1" # not yet tagged

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pothosware/SoapyPlutoSDR.git", "a07c37230369653818b3a5c448c00cee1ac9f8e5")
]

dependencies = [
    Dependency("libiio_jll"; compat="~0.24.0"),
    Dependency("soapysdr_jll"; compat="~0.8.0")
]

# Bash recipe for building across all platforms
script = raw"""
cd SoapyPlutoSDR

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
if [[ "${target}" == *-apple-* ]]; then
    mv ${libdir}/SoapySDR/modules0.8/libPlutoSDRSupport.so  ${libdir}/SoapySDR/modules0.8/libPlutoSDRSupport.dylib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)
platforms = expand_cxxstring_abis(platforms) # requested by auditor

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libPlutoSDRSupport", :libPlutoSDRSupport, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
