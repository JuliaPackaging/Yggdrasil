# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GStreamer"
version = v"1.18.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-$(version).tar.xz", "0c2e09e18f2df69a99b5cb3bd53c597b3cc2e35cf6c98043bb86a66f3d312100")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
apk add bash-completion
apk add libcap gettext
cd gstreamer-*
mkdir build
cd build
meson .. --cross-file=${MESON_TARGET_TOOLCHAIN}
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgstcheck-1.0", "libgstcheck-1"], :libgstcheck),
    ExecutableProduct("gst-tester-1.0", :gst_tester),
    LibraryProduct(["libgstnet-1.0", "libgstnet-1"], :libgstnet),
    LibraryProduct(["libgstreamer-1.0", "libgstreamer-1"], :libgstreamer),
    ExecutableProduct("gst-launch-1.0", :gst_launch),
    ExecutableProduct("gst-stats-1.0", :gst_stats),
    ExecutableProduct("gst-typefind-1.0", :gst_typefind),
    LibraryProduct(["libgstcontroller-1.0", "libgstcontroller-1"], :libgstcontroller),
    LibraryProduct(["libgstbase-1.0", "libgstbase-1"], :libgstbase),
    ExecutableProduct("gst-inspect-1.0", :gst_inspect)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"))
    Dependency(PackageSpec(name="LibUnwind_jll", uuid="745a5e78-f969-53e9-954f-d19f2f74f4e3"))
    Dependency(PackageSpec(name="Elfutils_jll", uuid="ab5a07f8-06af-567f-a878-e8bb879eba5a"))
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"), v"6.1.2")
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"))
    Dependency(PackageSpec(name="libcap_jll", uuid="eef66a8b-8d7a-5724-a8d2-7c31ae1e29ed"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
