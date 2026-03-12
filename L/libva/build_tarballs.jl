# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libva"
version = v"2.23.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/intel/libva.git", "e85b1569b738fd8866cb9fa2452319f7148d663f"),
]

# Bash recipe for building across all platforms
# Meson options from https://github.com/intel/libva/blob/2.23.0/meson_options.txt
# with_x11, with_wayland: combo (yes/no/auto), disable_drm: boolean
script = raw"""
cd $WORKSPACE/srcdir/libva

meson setup builddir \
    --cross-file=${MESON_TARGET_TOOLCHAIN} \
    --buildtype=release \
    -Dwith_x11=yes \
    -Dwith_wayland=no

meson compile -C builddir -j${nproc}
meson install -C builddir

install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libva", :libva),
    LibraryProduct("libva-drm", :libva_drm),
    LibraryProduct("libva-x11", :libva_x11),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libdrm_jll"),
    Dependency("Xorg_libX11_jll"),
    Dependency("Xorg_libXext_jll"),
    Dependency("Xorg_libXfixes_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
