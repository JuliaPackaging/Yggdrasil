# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Dbus"
version = v"1.12.16"

# Collection of sources required to build Dbus
sources = [
    "https://dbus.freedesktop.org/releases/dbus/dbus-$(version).tar.gz" =>
    "54a22d2fa42f2eb2a871f32811c6005b531b9613b1b93a0d269b05e7549fec80",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/dbus-*
./configure --prefix=${prefix} --host=${target} \
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
platforms = [p for p in supported_platforms() if p isa Union{Linux,FreeBSD}]

products = [
    LibraryProduct("libdbus-1", :libdbus),
    ExecutableProduct("dbus-daemon", :dbus_daemon)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Expat_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
