# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libavtp"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Avnu/libavtp/archive/refs/tags/v$(version).tar.gz", "9c1587431281a8d2404060e4bfd39f5cf0f211be6251e6afb1100e6148c1e591")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libavtp-*
mkdir build
cd build
meson --cross-file=${MESON_TARGET_TOOLCHAIN}
ninja
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(platform -> Sys.islinux(platform) && libc(platform) == "glibc", supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libavtp", :libavtp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="cmocka_jll", uuid="f83fd561-6387-5ecc-9835-b38c8eaffb11"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
