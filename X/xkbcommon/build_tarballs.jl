# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "xkbcommon"
version = v"1.13.0"

# Collection of sources required to build xkbcommon
sources = [
    GitSource("https://github.com/xkbcommon/libxkbcommon", "3049d310694fd70f1269bf48a1200aa4259e79b1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxkbcommon
meson setup builddir \
    --buildtype=release \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Denable-bash-completion=false  \
    -Denable-docs=false \
    -Denable-tools=false \
    -Denable-xkbregistry=false
meson compile -C builddir
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libxkbcommon", :libxkbcommon),
    LibraryProduct("libxkbcommon-x11", :libxkbcommon_x11),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Xorg_xkeyboard_config_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
