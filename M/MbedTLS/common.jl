using BinaryBuilder, Pkg

name = "MbedTLS"

# Collection of sources required to build MbedTLS
sources_by_version = Dict(
    v"2.24.0" => [
        GitSource("https://github.com/Mbed-TLS/mbedtls.git",
                  "523f0554b6cdc7ace5d360885c3f5bbcc73ec0e8"),
        DirectorySource("./bundled"; follow_symlinks=true),
    ],
    v"2.25.0" => [
        GitSource("https://github.com/Mbed-TLS/mbedtls.git",
                  "1c54b5410fd48d6bcada97e30cac417c5c7eea67"),
        DirectorySource("./bundled"; follow_symlinks=true),
    ],
    v"2.26.0" => [
        GitSource("https://github.com/Mbed-TLS/mbedtls.git",
                  "e483a77c85e1f9c1dd2eb1c5a8f552d2617fe400"),
        DirectorySource("./bundled"; follow_symlinks=true),
    ],
    v"2.27.0" => [
        GitSource("https://github.com/Mbed-TLS/mbedtls.git",
                  "f71e2878084126737cc39083e1e15afc459bd93d"),
        DirectorySource("./bundled"; follow_symlinks=true),
    ],
    v"2.28.0" => [
        GitSource("https://github.com/Mbed-TLS/mbedtls.git",
                  "8b3f26a5ac38d4fdccbc5c5366229f3e01dafcc0"),
        DirectorySource("./bundled"; follow_symlinks=true),
    ],
    v"2.28.1" => [
        GitSource("https://github.com/Mbed-TLS/mbedtls.git",
                  "dd79db10014d85b26d11fe57218431f2e5ede6f2"),
        DirectorySource("./bundled"; follow_symlinks=true),
    ],
    v"2.28.2" => [
        GitSource("https://github.com/Mbed-TLS/mbedtls.git",
                  "89f040a5c938985c5f30728baed21e49d0846a53"),
        DirectorySource("./bundled"; follow_symlinks=true),
    ],
    v"2.28.6" => [
        GitSource("https://github.com/Mbed-TLS/mbedtls.git",
                  "3a91dad9dceb484eea8b41f8941facafc4520021"),
        DirectorySource("./bundled"; follow_symlinks=true),
    ],
)
sources = sources_by_version[version]

# Bash recipe for building across all platforms
script = raw"""
shopt -s nullglob
cd $WORKSPACE/srcdir/mbedtls

# llvm-ranlib gets confused, use the binutils one
if [[ "${target}" == *apple* ]]; then
    ln -sf /opt/${target}/bin/${target}-ranlib /opt/bin/ranlib
    ln -sf /opt/${target}/bin/${target}-ranlib /opt/bin/${target}-ranlib
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/conditional/0001-Remove-flags-not-supported-by-ranlib.patch"
fi
if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi
# Apply patches that differ depending on the version of MbedTLS that we're building
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 "${f}"
done

# enable MD4
sed "s|//#define MBEDTLS_MD4_C|#define MBEDTLS_MD4_C|" -i include/mbedtls/config.h

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_C_STANDARD=99 \
    -DUSE_SHARED_MBEDTLS_LIBRARY=On \
    -DMBEDTLS_FATAL_WARNINGS=OFF \
    -DENABLE_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
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
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libmbedcrypto", :libmbedcrypto),
    LibraryProduct("libmbedx509", :libmbedx509),
    LibraryProduct("libmbedtls", :libmbedtls),
]

# Dependencies that must be installed before this package can be built
llvm_version = v"13.0.1+1"
dependencies = [
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
                    platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
]
