# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Dbus"
version = v"1.15.8"

# Collection of sources required to build Dbus
sources = [
    ArchiveSource("https://dbus.freedesktop.org/releases/dbus/dbus-$(version).tar.xz",
                  "84fc597e6ec82f05dc18a7d12c17046f95bad7be99fc03c15bc254c4701ed204"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/dbus-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-xml=expat \
    --with-dbus-user=messagebus \
    --with-system-pid-file=/var/run/dbus.pid \
    --disable-verbose-mode \
    --disable-static \
    --enable-inotify \
    --disable-dnotify \
    --disable-asserts \
    --enable-user-session \
    --with-session-socket-dir=/tmp \
    --with-x
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms())

products = [
    LibraryProduct("libdbus-1", :libdbus),
    ExecutableProduct("dbus-daemon", :dbus_daemon)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Expat_jll"; compat="2.2.7"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
