# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xcb_util_keysyms"
version = v"0.4.1"

# Collection of sources required to build libxcb
sources = [
    ArchiveSource("https://xcb.freedesktop.org/dist/xcb-util-keysyms-$(version).tar.xz",
                  "7c260a5294412aed429df1da2f8afd3bd07b7cba3fec772fba15a613a6d5c638"),
    FileSource("https://raw.githubusercontent.com/archlinux/svntogit-packages/ecd23f4fbd4d7670a182e24c29d99a6b8b817aba/trunk/LICENSE",
               "ded299aa179dcf0d885bf89274a4db77a530e03f9f5e7cf1c3c4ef1d60e914b9"; filename="LICENSE"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xcb-util-keysyms-*/

# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no
make -j${nproc}
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->!(Sys.islinux(p) || Sys.isfreebsd(p)))

products = [
    LibraryProduct("libxcb-keysyms", :libxcb_keysyms),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_xcb_util_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
