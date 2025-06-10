# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libepoxy"
version = v"1.5.11" # upstream is 1.5.10, but we needed a version bump

# Collection of sources required to build Libepoxy
sources = [
    GitSource("https://github.com/anholt/libepoxy.git", "c84bc9459357a40e46e2fec0408d04fbdde2c973")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/libepoxy
mkdir build && cd build
meson .. -Dtests=false --buildtype=release --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libepoxy", :libepoxy),
]

linux_freebsd = filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libglvnd_jll"),
    Dependency("Xorg_libX11_jll"; platforms=linux_freebsd),
    BuildDependency("Xorg_xorgproto_jll"; platforms=linux_freebsd),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; clang_use_lld=false, julia_compat="1.6")
