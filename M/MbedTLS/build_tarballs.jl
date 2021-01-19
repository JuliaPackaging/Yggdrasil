using BinaryBuilder

name = "MbedTLS"
version = v"2.25.0"

# Collection of sources required to build MbedTLS
sources = [
    GitSource("https://github.com/ARMmbed/mbedtls.git",
              "1c54b5410fd48d6bcada97e30cac417c5c7eea67"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mbedtls

# llvm-ranlib gets confused, use the binutils one
if [[ "${target}" == *apple* ]]; then
    ln -sf /opt/${target}/bin/${target}-ranlib /opt/bin/ranlib
    ln -sf /opt/${target}/bin/${target}-ranlib /opt/bin/${target}-ranlib
    atomic_patch -p1 ../patches/0001-Remove-flags-not-sopported-by-ranlib.patch
fi

# enable MD4
sed "s|//#define MBEDTLS_MD4_C|#define MBEDTLS_MD4_C|" -i include/mbedtls/config.h

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_C_STANDARD=99 \
    -DUSE_SHARED_MBEDTLS_LIBRARY=On \
    ..
make -j${nproc}
make install

if [[ "${target}" == *mingw* ]]; then
    # For some reason, the build system doesn't set the `.dll` files as
    # executable, which prevents them from being loaded.  Also, we need
    # to explicitly use `${prefix}/lib` here because the build system
    # is a simple one, and blindly uses `/lib`, even on Windows.
    chmod +x ${prefix}/lib/*.dll
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmbedcrypto", :libmbedcrypto),
    LibraryProduct("libmbedx509", :libmbedx509),
    LibraryProduct("libmbedtls", :libmbedtls),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7")
