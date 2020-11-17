# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libdrm"
version = v"2.4.103"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://dri.freedesktop.org/libdrm/libdrm-2.4.103.tar.xz", "3fe0affdba6460166a7323290c18cf68e9b59edcb520722826cb244e9cb50222"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd libdrm-*
meson --cross-file=${MESON_TARGET_TOOLCHAIN} -Dudev=false -Dvalgrind=false build
ninja -C build install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(Sys.islinux, supported_platform())


# The products that we will ensure are always built
products = [
    LibraryProduct("libdrm", :libdrm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Xorg_libpciaccess_jll", uuid="a65dc6b1-eb27-53a1-bb3e-dea574b5389e"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
