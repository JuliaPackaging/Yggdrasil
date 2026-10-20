# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "P11Kit"
version = v"0.26.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/p11-glue/p11-kit/releases/download/$(version)/p11-kit-$(version).tar.xz",
                  "09fd9f44da4813a3141e73d5e7cf7008e5660d0405f13d56c15e1da9dcecf828"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/p11-kit-*

meson setup --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release builddir
meson compile -C builddir
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    # p11-kit-client.so is not built on Windows, so we temporarily disable it
    # LibraryProduct("p11-kit-client", :libp11kitclient, "lib/pkcs11"),
    LibraryProduct("libp11-kit", :libp11kit),
    ExecutableProduct("p11-kit", :p11kit)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libffi_jll"; compat="3.4.7"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Prefer GCC 6 to define `memcpy@GLIBC_2.14'`
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
