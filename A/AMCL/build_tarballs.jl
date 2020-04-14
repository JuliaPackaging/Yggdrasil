# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "AMCL"
version = v"2.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/apache/incubator-milagro-crypto-c/archive/$version.tar.gz", "48fc7e0d7ad5edbfe8a779dc56f28813c25798ddfd60f1d94ccf1203eacd5645"),
]

# Bash recipe for building across all platforms
script = raw"""
env | sort
cd "$WORKSPACE/srcdir"/incubator-milagro-crypto-c-*
mkdir build
cd build
cmake -G "Ninja" -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" -DBUILD_BENCHMARKS=off -DBUILD_DOCS=off -DBUILD_EXAMPLES=off -DBUILD_PYTHON=off -DBUILD_TESTING=off -DWORD_SIZE=$nbits ..
ninja
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libamcl_bls_BLS24", :libamcl_bls_BLS24),
    LibraryProduct("libamcl_bls_BLS381", :libamcl_bls_BLS381),
    LibraryProduct("libamcl_bls_BLS383", :libamcl_bls_BLS383),
    LibraryProduct("libamcl_bls_BLS461", :libamcl_bls_BLS461),
    LibraryProduct("libamcl_bls_BLS48", :libamcl_bls_BLS48),
    LibraryProduct("libamcl_bls_BN254", :libamcl_bls_BN254),
    LibraryProduct("libamcl_bls_BN254CX", :libamcl_bls_BN254CX),
    LibraryProduct("libamcl_bls_FP256BN", :libamcl_bls_FP256BN),
    LibraryProduct("libamcl_bls_FP512BN", :libamcl_bls_FP512BN),
    LibraryProduct("libamcl_core", :libamcl_core),
    LibraryProduct("libamcl_curve_ANSSI", :libamcl_curve_ANSSI),
    LibraryProduct("libamcl_curve_BLS24", :libamcl_curve_BLS24),
    LibraryProduct("libamcl_curve_BLS381", :libamcl_curve_BLS381),
    LibraryProduct("libamcl_curve_BLS383", :libamcl_curve_BLS383),
    LibraryProduct("libamcl_curve_BLS461", :libamcl_curve_BLS461),
    LibraryProduct("libamcl_curve_BLS48", :libamcl_curve_BLS48),
    LibraryProduct("libamcl_curve_BN254", :libamcl_curve_BN254),
    LibraryProduct("libamcl_curve_BN254CX", :libamcl_curve_BN254CX),
    LibraryProduct("libamcl_curve_BRAINPOOL", :libamcl_curve_BRAINPOOL),
    LibraryProduct("libamcl_curve_C25519", :libamcl_curve_C25519),
    LibraryProduct("libamcl_curve_C41417", :libamcl_curve_C41417),
    LibraryProduct("libamcl_curve_ED25519", :libamcl_curve_ED25519),
    LibraryProduct("libamcl_curve_FP256BN", :libamcl_curve_FP256BN),
    LibraryProduct("libamcl_curve_FP512BN", :libamcl_curve_FP512BN),
    LibraryProduct("libamcl_curve_GOLDILOCKS", :libamcl_curve_GOLDILOCKS),
    LibraryProduct("libamcl_curve_HIFIVE", :libamcl_curve_HIFIVE),
    LibraryProduct("libamcl_curve_NIST256", :libamcl_curve_NIST256),
    LibraryProduct("libamcl_curve_NIST384", :libamcl_curve_NIST384),
    LibraryProduct("libamcl_curve_NIST521", :libamcl_curve_NIST521),
    LibraryProduct("libamcl_curve_NUMS256E", :libamcl_curve_NUMS256E),
    LibraryProduct("libamcl_curve_NUMS256W", :libamcl_curve_NUMS256W),
    LibraryProduct("libamcl_curve_NUMS384E", :libamcl_curve_NUMS384E),
    LibraryProduct("libamcl_curve_NUMS384W", :libamcl_curve_NUMS384W),
    LibraryProduct("libamcl_curve_NUMS512E", :libamcl_curve_NUMS512E),
    LibraryProduct("libamcl_curve_NUMS512W", :libamcl_curve_NUMS512W),
    LibraryProduct("libamcl_curve_SECP256K1", :libamcl_curve_SECP256K1),
    LibraryProduct("libamcl_mpin_BLS24", :libamcl_mpin_BLS24),
    LibraryProduct("libamcl_mpin_BLS381", :libamcl_mpin_BLS381),
    LibraryProduct("libamcl_mpin_BLS383", :libamcl_mpin_BLS383),
    LibraryProduct("libamcl_mpin_BLS461", :libamcl_mpin_BLS461),
    LibraryProduct("libamcl_mpin_BLS48", :libamcl_mpin_BLS48),
    LibraryProduct("libamcl_mpin_BN254", :libamcl_mpin_BN254),
    LibraryProduct("libamcl_mpin_BN254CX", :libamcl_mpin_BN254CX),
    LibraryProduct("libamcl_mpin_FP256BN", :libamcl_mpin_FP256BN),
    LibraryProduct("libamcl_mpin_FP512BN", :libamcl_mpin_FP512BN),
    LibraryProduct("libamcl_pairing_BLS24", :libamcl_pairing_BLS24),
    LibraryProduct("libamcl_pairing_BLS381", :libamcl_pairing_BLS381),
    LibraryProduct("libamcl_pairing_BLS383", :libamcl_pairing_BLS383),
    LibraryProduct("libamcl_pairing_BLS461", :libamcl_pairing_BLS461),
    LibraryProduct("libamcl_pairing_BLS48", :libamcl_pairing_BLS48),
    LibraryProduct("libamcl_pairing_BN254", :libamcl_pairing_BN254),
    LibraryProduct("libamcl_pairing_BN254CX", :libamcl_pairing_BN254CX),
    LibraryProduct("libamcl_pairing_FP256BN", :libamcl_pairing_FP256BN),
    LibraryProduct("libamcl_pairing_FP512BN", :libamcl_pairing_FP512BN),
    LibraryProduct("libamcl_rsa_2048", :libamcl_rsa_2048),
    LibraryProduct("libamcl_rsa_3072", :libamcl_rsa_3072),
    LibraryProduct("libamcl_rsa_4096", :libamcl_rsa_4096),
    LibraryProduct("libamcl_wcc_BLS24", :libamcl_wcc_BLS24),
    LibraryProduct("libamcl_wcc_BLS381", :libamcl_wcc_BLS381),
    LibraryProduct("libamcl_wcc_BLS383", :libamcl_wcc_BLS383),
    LibraryProduct("libamcl_wcc_BLS461", :libamcl_wcc_BLS461),
    LibraryProduct("libamcl_wcc_BLS48", :libamcl_wcc_BLS48),
    LibraryProduct("libamcl_wcc_BN254", :libamcl_wcc_BN254),
    LibraryProduct("libamcl_wcc_BN254CX", :libamcl_wcc_BN254CX),
    LibraryProduct("libamcl_wcc_FP256BN", :libamcl_wcc_FP256BN),
    LibraryProduct("libamcl_wcc_FP512BN", :libamcl_wcc_FP512BN),
    LibraryProduct("libamcl_x509", :libamcl_x509),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
