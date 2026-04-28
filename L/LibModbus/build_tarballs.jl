# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibModbus"
version = v"3.1.12"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/stephane/libmodbus.git", "9af6c16074df566551bca0a7c37443e48f216289")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libmodbus/
# Assert that the expected constant definition exists before patching
grep -q 'const uint16_t UT_BITS_ADDRESS = 0x130' tests/unit-test.h.in || \
    (echo "ERROR: Expected 'const uint16_t UT_BITS_ADDRESS = 0x130' not found in tests/unit-test.h.in" && exit 1)
# Replace the non-constant initializer expression with a literal value
sed -i 's/const uint16_t UT_BITS_ADDRESS_INVALID_REQUEST_LENGTH = UT_BITS_ADDRESS + 2/const uint16_t UT_BITS_ADDRESS_INVALID_REQUEST_LENGTH = 0x132/g' tests/unit-test.h.in
./autogen.sh 
./configure --prefix=$prefix --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license COPYING.LESSER
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmodbus", :libmodbus)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
