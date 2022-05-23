# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "seatd"
version = v"0.5.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://git.sr.ht/~kennylevinsen/seatd/archive/$version.tar.gz", "274b56324fc81ca6002bc1cdd387668dee34a6e1063e5f3896805c3770948988"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/seatd-*/
atomic_patch ../patches/fix_crosscompile.patch
mkdir build
cd build
apk add meson scdoc

PKG_CONFIG_SYSROOT_DIR="" meson ../ --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p ->Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libseat", :libseat),
    ExecutableProduct("seatd", :seatd),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", julia_compat="1.6")
