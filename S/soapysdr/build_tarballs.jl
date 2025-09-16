# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "soapysdr"
version = v"0.8.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pothosware/SoapySDR.git", "1cf5a539a21414ff509ff7d0eedfc5fa8edb90c6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SoapySDR/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
install_license LICENSE_1_0.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libSoapySDR", :libsoapysdr),
    ExecutableProduct("SoapySDRUtil", :soapysdrutil)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
