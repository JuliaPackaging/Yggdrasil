# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, Base.BinaryPlatforms

name = "SoapyBladeRF"
version = v"0.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pothosware/SoapyBladeRF.git", "85f6dc554ed4c618304d99395b19c4e1523675b0")
]

dependencies = [
    Dependency("soapysdr_jll"; compat="0.8.0"),
    Dependency("BladeRFHardwareDriver_jll"; compat="2.4.1")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir SoapyBladeRF/_build
cd SoapyBladeRF/_build

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      ..

make -j${nproc}
install -Dvm 755 "libbladeRFSupport.so" "${libdir}/SoapySDR/modules0.8/libbladeRFSupport.${dlext}"
install_license $WORKSPACE/srcdir/SoapyBladeRF/LICENSE.LGPLv2.1
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libbladeRFSupport", :libbladeRFSupport, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
