# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoapyPlutoSDR"
version = v"0.2.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pothosware/SoapyPlutoSDR.git", "422a9b306f765499dd3e9a4c3400fa39816dcfdb")
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
platforms = filter(platforms) do p
    os(p) == "freebsd" && arch(p) == "aarch64" && return false
    arch(p) == "riscv64" && return false
    return true
end
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libPlutoSDRSupport", :libPlutoSDRSupport, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
