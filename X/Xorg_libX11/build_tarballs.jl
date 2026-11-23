# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libX11"
version = v"1.8.14"

# Collection of sources required to build libX11
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libX11-$(version).tar.xz",
                  "bbc78c46217174655c2b32b138ad119f3ac15f50808b4d0b3a2677a4b1afc950"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libX11-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-static=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->!(Sys.islinux(p) || Sys.isfreebsd(p)))


products = [
    LibraryProduct("libX11", :libX11),
    LibraryProduct("libX11-xcb", :libX11_xcb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Xorg_xtrans_jll"),
]

# The locale data path is compiled in as `${prefix}/share/X11/locale`, which doesn't
# exist outside the build environment. Without it XSupportsLocale() fails and no input
# method can be opened.
init_block = raw"""
ENV["XLOCALEDIR"] = get(ENV, "XLOCALEDIR", joinpath(artifact_dir, "share", "X11", "locale"))
"""

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", init_block)
