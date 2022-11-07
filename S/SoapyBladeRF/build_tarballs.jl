# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, Base.BinaryPlatforms

name = "SoapyBladeRF"
version = v"2.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pothosware/SoapyBladeRF.git", "85f6dc554ed4c618304d99395b19c4e1523675b0")
]

dependencies = [
    Dependency("soapysdr_jll"; compat="0.8.0"),
    Dependency(PackageSpec(name = "BladeRFHardwareDriver_jll",  uuid = "ddcda2f0-0770-5eff-b02e-03a583a735ee", path="/home/schoenbrod/.julia/dev/BladeRFHardwareDriver_jll"); compat="2.4.1")
]

# Bash recipe for building across all platforms
script = raw"""
cd SoapyBladeRF
mkdir _build
cd _build

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      ..
make -j${nproc}
make install
if [[ "${target}" == *-apple-* ]]; then
    mv ${libdir}/SoapySDR/modules0.8/libbladeRFSupport.so ${libdir}/SoapySDR/modules0.8/libbladeRFSupport.dylib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; )
]

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libbladeRFSupport", :libbladeRFSupport, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
