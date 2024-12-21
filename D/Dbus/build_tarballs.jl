# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Dbus"
version = v"1.14.10"

# NOTE: Next stable version 1.16 will require cmake for Windows and meson for everything
# else. Check [here](https://cgit.freedesktop.org/dbus/dbus/tree/NEWS?h=master#n21).

# Collection of sources required to build Dbus
sources = [
    ArchiveSource("https://dbus.freedesktop.org/releases/dbus/dbus-$(version).tar.xz",
                  "ba1f21d2bd9d339da2d4aa8780c09df32fea87998b73da24f49ab9df1e36a50f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/dbus-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-dbus-user=messagebus \
    --with-system-pid-file=/var/run/dbus.pid \
    --disable-verbose-mode \
    --disable-static \
    --enable-inotify \
    --disable-asserts \
    --enable-user-session \
    --with-session-socket-dir=/tmp \
    --with-x=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libdbus-1", :libdbus),
    ExecutableProduct("dbus-daemon", :dbus_daemon)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Expat_jll", uuid="2e619515-83b5-522b-bb60-26c02a35a201"); compat="2.2.10"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
