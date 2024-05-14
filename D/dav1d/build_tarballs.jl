# Note that this script can accept some limited command-line arguments,
# run `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "dav1d"
version = v"1.4.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://code.videolan.org/videolan/dav1d/-/archive/$(version)/dav1d-$(version).tar.bz2",
                  "ab02c6c72c69b2b24726251f028b7cb57d5b3659eeec9f67f6cecb2322b127d8"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/dav1d-*

# Avoid problems with `-Werror=unused-command-line-argument`
sed -i -e 's!/opt/bin/.*-clang!'${WORKSPACE}/srcdir/files/cc'!' ${MESON_TARGET_TOOLCHAIN}
sed -i -e 's!/opt/bin/.*-clang[+][+]!'${WORKSPACE}/srcdir/files/c++'!' ${MESON_TARGET_TOOLCHAIN}

mkdir build && cd build
meson setup --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release -Denable_tests=false ..
ninja -j${nproc}
ninja install
install_license ../COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("dav1d", :dav1d),
    LibraryProduct("libdav1d", :libdav1d),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("NASM_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Need at least GCC 6 for Atomics and to avoid ICEs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
