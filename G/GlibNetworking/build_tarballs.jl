# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GlibNetworking"
version = v"2.74.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/glib-networking/2.74/glib-networking-$(version).tar.xz", "1f185aaef094123f8e25d8fa55661b3fd71020163a0174adb35a37685cda613b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glib-networking-*
install_license COPYING

mkdir build-glib && cd build-glib
meson --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release ..

# Meson beautifully forces thin archives, without checking whether the dynamic linker
# actually supports them: <https://github.com/mesonbuild/meson/issues/10823>.  Let's remove
# the (deprecated...) `T` option to `ar`
sed -i.bak 's/csrDT/csrD/' build.ninja

ninja -j${nproc}

# Darwin products are also .so instead of .dylib so we need to rename
cp proxy/environment/libgioenvironmentproxy.so ${libdir}/libgioenvironmentproxy.${dlext}
cp tls/gnutls/libgiognutls.so ${libdir}/libgioenvironmentproxy.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgioenvironmentproxy", :libgioenvironmentproxy),
    LibraryProduct("libgiognutls", :libgiognutls)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Host gettext needed for "msgfmt"
    HostBuildDependency("Gettext_jll")
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"))
    Dependency(PackageSpec(name="GnuTLS_jll", uuid="0951126a-58fd-58f1-b5b3-b08c7c4a876d"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
