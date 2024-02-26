# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GStreamer"
version = v"1.20.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-$(version).tar.xz",
                  "607daf64bbbd5fb18af9d17e21c0d22c4d702fffe83b23cb22d1b1af2ca23a2a"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gstreamer-*
mkdir build
cd build
if [[ "${target}" == *-mingw* ]]; then
    # Need to tell we're targeting at least Windows 7 so that `FILE_STANDARD_INFO` is defined
    sed -ri "s/^c_args = \[(.*)\]/c_args = [\1, '-DWINVER=_WIN32_WINNT_WIN7', '-D_WIN32_WINNT=_WIN32_WINNT_WIN7']/" ${MESON_TARGET_TOOLCHAIN}
    # Install right version of `pthread_time.h` which defines `CLOCK_MONOTONIC` and `TIMER_ABSTIME`
    cp -v ${WORKSPACE}/srcdir/headers/pthread_time.h "/opt/${target}/${target}/sys-root/include/pthread_time.h"
fi
meson .. --cross-file=${MESON_TARGET_TOOLCHAIN}

# Meson beautifully forces thin archives, without checking whether the dynamic linker
# actually supports them: <https://github.com/mesonbuild/meson/issues/10823>.  Let's remove
# the (deprecated...) `T` option to `ar`, until they fix it in Meson.
sed -i.bak 's/csrDT/csrD/' build.ninja

ninja -j${nproc}
ninja install
install_license ../COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=[Platform("i686", "linux", libc = "musl"), Platform("powerpc64le", "linux")])

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgstbase-1.0", "libgstbase-1"], :libgstbase),
    LibraryProduct(["libgstcheck-1.0", "libgstcheck-1"], :libgstcheck),
    LibraryProduct(["libgstcontroller-1.0", "libgstcontroller-1"], :libgstcontroller),
    LibraryProduct(["libgstnet-1.0", "libgstnet-1"], :libgstnet),
    LibraryProduct(["libgstreamer-1.0", "libgstreamer-1"], :libgstreamer),
    ExecutableProduct("gst-inspect-1.0", :gst_inspect),
    ExecutableProduct("gst-launch-1.0", :gst_launch),
    ExecutableProduct("gst-stats-1.0", :gst_stats),
    ExecutableProduct("gst-tester-1.0", :gst_tester),
    ExecutableProduct("gst-typefind-1.0", :gst_typefind),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need a host gettext for msgfmt
    HostBuildDependency("Gettext_jll")
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"); compat="2.68.1")
    Dependency(PackageSpec(name="LibUnwind_jll", uuid="745a5e78-f969-53e9-954f-d19f2f74f4e3"); platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms))
    Dependency(PackageSpec(name="Elfutils_jll", uuid="ab5a07f8-06af-567f-a878-e8bb879eba5a"); platforms=filter(Sys.islinux, platforms))
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"); compat="6.2.0")
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"); compat="~2.7.2")
    Dependency(PackageSpec(name="libcap_jll", uuid="eef66a8b-8d7a-5724-a8d2-7c31ae1e29ed"); platforms=filter(Sys.islinux, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
