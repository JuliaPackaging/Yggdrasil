# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, Base.BinaryPlatforms

name = "SoapyUHD"
version = v"0.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pothosware/SoapyUHD.git", "d8aba947a01a530b1d9c2f4a07e4241bbd04d327")
]

dependencies = [
    Dependency("soapysdr_jll"; compat="0.8.0"),
    Dependency("boost_jll"; compat="=1.76.0"), # max gcc7
    Dependency("USRPHardwareDriver_jll"; compat="4.1.0")
]

# Bash recipe for building across all platforms
script = raw"""
cd SoapyUHD
mkdir _build
cd _build

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      ..
make -j${nproc}
make install
if [[ "${target}" == *-apple-* ]]; then
    mv ${libdir}/SoapySDR/modules0.8/libuhdSupport.so  ${libdir}/SoapySDR/modules0.8/libuhdSupport.dylib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> !Sys.iswindows(p) && !in(arch(p),("armv7l","armv6l")), supported_platforms(;experimental=true))
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libuhdSupport", :libuhdSupport, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
