using BinaryBuilder

name = "MbedTLS"
version = v"2.16.0"

# Collection of sources required to build MbedTLS
sources = [
    "https://github.com/ARMmbed/mbedtls.git" =>
    "fb1972db23da39bd11d4f9c9ea6266eee665605b",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mbedtls
mkdir -p $prefix/lib

# llvm-ranlib gets confused, use binutils
if [[ "${target}" == *apple* ]]; then
    ln -sf /opt/${target}/bin/${target}-ranlib /opt/bin/ranlib
fi
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" -DUSE_SHARED_MBEDTLS_LIBRARY=On
make -j${nproc} && make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmbedcrypto", :libmbedcrypto),
    LibraryProduct("libmbedx509", :libmbedx509),
    LibraryProduct("libmbedtls", :libmbedtls)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
