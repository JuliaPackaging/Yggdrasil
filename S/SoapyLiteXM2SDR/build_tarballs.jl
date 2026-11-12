# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoapyLiteXM2SDR"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/enjoy-digital/litex_m2sdr.git", "1f15d3f0ca082b7df232ca698f9413ef9ca0d77f"),
    DirectorySource("./bundled")
]

dependencies = [
    Dependency("soapysdr_jll"; compat="0.8.0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/litex_m2sdr

# Apply patches
atomic_patch -p1 ../patches/fix_cmake_liteeth.patch
atomic_patch -p1 ../patches/fix_util_h_macros.patch

# Build user libraries first
echo "Building user libraries..."
cd litex_m2sdr/software/user
make INTERFACE=USE_LITEPCIE liblitepcie/liblitepcie.a libm2sdr/libm2sdr.a ad9361/libad9361_m2sdr.a

# Verify libraries were built
if [ ! -f liblitepcie/liblitepcie.a ] || [ ! -f libm2sdr/libm2sdr.a ]; then
    echo "Error: Failed to build user libraries"
    exit 1
fi

echo "User libraries built successfully"

# Build SoapySDR module
echo "Building SoapySDR module..."
cd ../soapysdr
mkdir build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_LITEETH=OFF

make -j${nproc}

# Install the module
install -Dvm 755 "libSoapyLiteXM2SDR.${dlext}" "${libdir}/SoapySDR/modules0.8/libSoapyLiteXM2SDR.${dlext}"

# Install license
install_license ${WORKSPACE}/srcdir/litex_m2sdr/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# LiteX M2SDR is a PCIe device that only works on Linux
# Exclude RISC-V as it's not commonly used with PCIe hardware and has build issues
platforms = filter(Sys.islinux, supported_platforms())
platforms = filter(p -> arch(p) != "riscv64", platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libSoapyLiteXM2SDR", :libSoapyLiteXM2SDR, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
