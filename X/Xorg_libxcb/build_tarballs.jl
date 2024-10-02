# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libxcb"
version_string = "1.17.0"
version = VersionNumber(version_string)

# Collection of sources required to build libxcb
sources = [
    ArchiveSource("https://www.x.org/archive/individual/xcb/libxcb-$(version_string).tar.xz",
                  "599ebf9996710fea71622e6e184f3a8ad5b43d0e5fa8c4e407123c88a59a6d55"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxcb-*/
CPPFLAGS="-I${prefix}/include"
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libxcb-composite", :libxcb_composite),
    LibraryProduct("libxcb-damage", :libxcb_damage),
    LibraryProduct("libxcb-dpms", :libxcb_dpms),
    LibraryProduct("libxcb-dri2", :libxcb_dri2),
    LibraryProduct("libxcb-dri3", :libxcb_dri3),
    LibraryProduct("libxcb-glx", :libxcb_glx),
    LibraryProduct("libxcb-present", :libxcb_present),
    LibraryProduct("libxcb-randr", :libxcb_randr),
    LibraryProduct("libxcb-record", :libxcb_record),
    LibraryProduct("libxcb-render", :libxcb_render),
    LibraryProduct("libxcb-res", :libxcb_res),
    LibraryProduct("libxcb-screensaver", :libxcb_screensaver),
    LibraryProduct("libxcb-shape", :libxcb_shape),
    LibraryProduct("libxcb-shm", :libxcb_shm),
    LibraryProduct("libxcb", :libxcb),
    LibraryProduct("libxcb-sync", :libxcb_sync),
    LibraryProduct("libxcb-xf86dri", :libxcb_xf86dri),
    LibraryProduct("libxcb-xfixes", :libxcb_xfixes),
    LibraryProduct("libxcb-xinerama", :libxcb_xinerama),
    LibraryProduct("libxcb-xinput", :libxcb_xinput),
    LibraryProduct("libxcb-xkb", :libxcb_xkb),
    LibraryProduct("libxcb-xtest", :libxcb_xtest),
    LibraryProduct("libxcb-xvmc", :libxcb_xvmc),
    LibraryProduct("libxcb-xv", :libxcb_xv),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_util_macros_jll"),
    BuildDependency("Xorg_xproto_jll"),
    BuildDependency("Xorg_xcb_proto_jll"),
    Dependency("XSLT_jll"),
    Dependency("Xorg_libXau_jll"),
    Dependency("Xorg_libXdmcp_jll"),
    Dependency("Xorg_libpthread_stubs_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
