# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoapyHackRF"
version = v"0.3.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pothosware/SoapyHackRF.git", "79077f0425f732954c1d74dbbacd788b0ac7d733")
]

dependencies = [
#    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("hackrf_jll"; compat="2026.1.3"),
    Dependency("soapysdr_jll"; compat="0.8.0")
]

# Bash recipe for building across all platforms
script = raw"""
cd SoapyHackRF
mkdir build && cd build
cmake -B . -S .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libHackRFSupport", :libHackRFSupport, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs, and possibly a `build.jl` as well.
# gcc7 constraint from boost
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
