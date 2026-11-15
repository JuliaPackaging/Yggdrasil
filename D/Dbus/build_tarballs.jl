# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Dbus"
version = v"1.16.2"

# NOTE: Next stable version 1.16 will require cmake for Windows and meson for everything
# else. Check [here](https://cgit.freedesktop.org/dbus/dbus/tree/NEWS?h=master#n21).

# Collection of sources required to build Dbus
sources = [
    ArchiveSource("https://dbus.freedesktop.org/releases/dbus/dbus-$(version).tar.xz",
                  "0ba2a1a4b16afe7bceb2c07e9ce99a8c2c3508e5dec290dbb643384bd6beb7e2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/dbus-*

# -Dinotify=enabled ?
options=(
    --buildtype=release
    --cross-file=${MESON_TARGET_TOOLCHAIN}
    --prefix=${prefix}
    -Ddbus_user=messagebus
    -Dsystem_pid_file=/var/run/dbus.pid
    -Dverbose_mode=false
    -Dinotify=auto
    -Dasserts=false
    -Duser_session=true
    -Dsession_socket_dir=/tmp
    -Dx11_autolaunch=disabled
    -Dmodular_tests=disabled
    -Dc_link_args='-lrt'
)

if [[ ${target} == x86_64-*-freebsd* ]]; then
    # The symbol `environ` is not provided by a shared library but by `crt1.o`, which is only loaded at run time.
    # We thus cannot check for undefined references during linking.
    options+=(-Db_lundef=false)
fi

meson setup builddir "${options[@]}"
meson compile -C builddir
meson install -C builddir
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
    Dependency(PackageSpec(name="Expat_jll", uuid="2e619515-83b5-522b-bb60-26c02a35a201"); compat="2.6.5"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
