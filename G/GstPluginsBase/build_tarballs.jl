# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GstPluginsBase"
version = v"1.20.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-$(version).tar.xz", "7e30b3dd81a70380ff7554f998471d6996ff76bbe6fc5447096f851e24473c9f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
meson --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release gst-plugins-base-*
ninja -j${nproc}
ninja install
install_license gst-plugins-base-*/COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=[Platform("i686", "linux", libc = "musl"), Platform("powerpc64le", "linux")])

# The products that we will ensure are always built
products = [
    LibraryProduct("libgstpbtypes", :libgstpbtypes, "lib/gstreamer-1.0"),
    LibraryProduct("libgstoverlaycomposition", :libgstoverlaycomposition, "lib/gstreamer-1.0"),
    LibraryProduct("libgstaudiotestsrc", :libgstaudiotestsrc, "lib/gstreamer-1.0"),
    LibraryProduct("libgstaudiomixer", :libgstaudiomixer, "lib/gstreamer-1.0"),
    LibraryProduct("libgstadder", :libgstadder, "lib/gstreamer-1.0"),
    LibraryProduct("libgstvideorate", :libgstvideorate, "lib/gstreamer-1.0"),
    LibraryProduct("libgstvideoconvert", :libgstvideoconvert, "lib/gstreamer-1.0"),
    LibraryProduct("libgstopus", :libgstopus, "lib/gstreamer-1.0"),
    LibraryProduct("libgstrawparse", :libgstrawparse, "lib/gstreamer-1.0"),
    LibraryProduct("libgsttcp", :libgsttcp, "lib/gstreamer-1.0"),
    LibraryProduct("libgstvolume", :libgstvolume, "lib/gstreamer-1.0"),
    LibraryProduct("libgstvideotestsrc", :libgstvideotestsrc, "lib/gstreamer-1.0"),
    LibraryProduct("libgsttypefindfunctions", :libgsttypefindfunctions, "lib/gstreamer-1.0"),
    LibraryProduct("libgstencoding", :libgstencoding, "lib/gstreamer-1.0"),
    LibraryProduct("libgstcompositor", :libgstcompositor, "lib/gstreamer-1.0"),
    LibraryProduct("libgstaudiorate", :libgstaudiorate, "lib/gstreamer-1.0"),
    LibraryProduct("libgstsubparse", :libgstsubparse, "lib/gstreamer-1.0"),
    LibraryProduct("libgstaudioconvert", :libgstaudioconvert, "lib/gstreamer-1.0"),
    LibraryProduct("libgstplayback", :libgstplayback, "lib/gstreamer-1.0"),
    LibraryProduct("libgstgio", :libgstgio, "lib/gstreamer-1.0"),
    LibraryProduct("libgstvideoscale", :libgstvideoscale, "lib/gstreamer-1.0"),
    LibraryProduct("libgstaudioresample", :libgstaudioresample, "lib/gstreamer-1.0"),
    LibraryProduct("libgstapp", :libgstapp, "lib/gstreamer-1.0"),
    ExecutableProduct("gst-device-monitor-1.0", :gstdevicemonitor),
    ExecutableProduct("gst-play-1.0", :gstplay),
    ExecutableProduct("gst-discoverer-1.0", :gstdiscoverer)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need a host gettext for msgfmt
    HostBuildDependency("Gettext_jll")
    Dependency(PackageSpec(name="GStreamer_jll", uuid="aaaaf01e-2457-52c6-9fe8-886f7267d736"); compat="1.20.3")
    Dependency(PackageSpec(name="Opus_jll", uuid="91d4177d-7536-5919-b921-800302f37372"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
