# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoapyMultiSDR"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pothosware/SoapyMultiSDR.git", "94cd6fff0b571f31c454c76bd38c80a18c52d234")
]

dependencies = [
    Dependency("soapysdr_jll"; compat="0.8.0")
]

# Bash recipe for building across all platforms
script = raw"""
cd SoapyMultiSDR
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      ..
make -j${nproc}
make install
if [[ "${target}" == *-apple-* ]]; then
    mv ${libdir}/SoapySDR/modules0.8/libMultiSDRSupport.so  ${libdir}/SoapySDR/modules0.8/libMultiSDRSupport.dylib
fi

install_license ../LICENSE_1_0.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libMultiSDRSupport", :librtlsdrSupport, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
