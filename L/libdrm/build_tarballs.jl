# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libdrm"
version = v"2.4.110"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://dri.freedesktop.org/libdrm/libdrm-$version.tar.xz", "eecee4c4b47ed6d6ce1a9be3d6d92102548ea35e442282216d47d05293cf9737"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libdrm-*
atomic_patch -p1 ../no_stress.patch
meson --cross-file=${MESON_TARGET_TOOLCHAIN} -Dudev=false -Dvalgrind=false build
ninja -C build install
# taken from https://salsa.debian.org/xorg-team/lib/libdrm/-/blob/libdrm-2.4.105-3/debian/copyright
install_license ../copyright
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(Sys.islinux, supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libdrm", :libdrm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Xorg_libpciaccess_jll", uuid="a65dc6b1-eb27-53a1-bb3e-dea574b5389e"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
