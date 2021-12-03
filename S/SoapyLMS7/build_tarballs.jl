# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, Base.BinaryPlatforms

name = "SoapyLMS7"
version = v"20.10.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/myriadrf/LimeSuite.git", "1480bfeaf4de211c40813fc5ca161b1b644778ec")
]

dependencies = [
    Dependency("soapysdr_jll"; compat="0.8.0"),
    Dependency("libusb_jll"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/LimeSuite
mkdir _build
cd _build

CMAKE_OPTIONS=(
    # Disable a bunch of things we don't care about
    -DENABLE_QUICKTEST=OFF
    -DENABLE_OCTAVE=OFF
    -DDOWNLOAD_IMAGES=FALSE
    -DENABLE_GUI=OFF
    -DENABLE_NOVENARF7=OFF

    # Disable SIMD for now; enable later if we need it
    # by expanding our microarchitectures
    -DDEFAULT_SIMD_FLAGS=cross

    # Enable the one thing we do care about
    -DENABLE_SOAPY_LMS7=ON
)

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      "${CMAKE_OPTIONS[@]}" \
      ..
make -j${nproc}
make install
if [[ "${target}" == *-apple-* ]]; then
    mv ${libdir}/SoapySDR/modules0.8/libLMS7Support.so  ${libdir}/SoapySDR/modules0.8/libLMS7Support.dylib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> os(p) != "windows", supported_platforms(;experimental=true))
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    # TODO: These should eventually be a separate output from this builder
    ExecutableProduct("LimeUtil", :LimeUtil),
    LibraryProduct("libLimeSuite", :libLimeSuite),
    LibraryProduct("libLMS7Support", :libLMS7Support, ["lib/SoapySDR/modules0.8/"]),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
