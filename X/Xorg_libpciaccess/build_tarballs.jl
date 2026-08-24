# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libpciaccess"
version_str = "0.19"
version = VersionNumber(version_str)

# Collection of sources required to build Libpciaccess
sources = [
    ArchiveSource("https://xorg.freedesktop.org/releases/individual/lib/libpciaccess-$(version_str).tar.xz",
                  "3c55aa86c82e54a4e3109786f0463530d53b36b6d1cfd14616454f985dd2aa43"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libpciaccess-*/
meson setup builddir --buildtype=release --cross-file=${MESON_TARGET_TOOLCHAIN} --prefix=${prefix}
meson compile -C builddir
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libpciaccess", :libpciaccess),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
