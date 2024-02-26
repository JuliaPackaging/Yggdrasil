# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xkeyboard_config"
version = v"2.39"

# Collection of sources required to build xkeyboard_config
sources = [
    ArchiveSource("https://www.x.org/archive/individual/data/xkeyboard-config/xkeyboard-config-$(version.major).$(version.minor).tar.xz",
                  "5ac5f533eff7b0c116805fe254fd79b2c9882700a4f9f2c070f8c4eae5aaa682"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xkeyboard-config-*
apk update && apk add libxslt
mkdir build && cd build
meson .. --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xproto_jll"),
    BuildDependency("Xorg_kbproto_jll"),
    Dependency("Xorg_xkbcomp_jll"),
]

init_block = raw"""
if Sys.islinux() || Sys.isfreebsd()
    ENV["XKB_CONFIG_ROOT"] = get(ENV, "XKB_CONFIG_ROOT", joinpath(artifact_dir, "share", "X11", "xkb"))
end
"""

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", init_block)
