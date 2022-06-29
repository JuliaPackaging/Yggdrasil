# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoapyRTLSDR"
version = v"0.3.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pothosware/SoapyRTLSDR.git", "80c93fbe189def3ab68d47a6ad3f813f96d3cb99")
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("librtlsdr_jll"; compat="0.6.0"),
    Dependency("soapysdr_jll"; compat="0.8.0")
]

# Bash recipe for building across all platforms
script = raw"""
cd SoapyRTLSDR
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      ..
make -j${nproc}
make install
if [[ "${target}" == *-apple-* ]]; then
    mv ${libdir}/SoapySDR/modules0.8/librtlsdrSupport.so  ${libdir}/SoapySDR/modules0.8/librtlsdrSupport.dylib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms(;experimental=true))
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("librtlsdrSupport", :librtlsdrSupport, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs, and possibly a `build.jl` as well.
# gcc7 constraint from boost
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
