
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "BlueZ"
version = v"5.54"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.kernel.org/pub/linux/bluetooth/bluez-$(version.major).$(version.minor).tar.xz", "68cdab9e63e8832b130d5979dc8c96fdb087b31278f342874d992af3e56656dc")
]

# Bash recipe for building across all platforms
script = raw"""
# I think a target version is actually needed, but this gets you pretty far
apk add libical-dev
cd bluez-*
# dooesn't seem to work, prevent configure from finding it
sed -i -e "s~ linux/if_alg.h~~" configure.ac 
autoconf
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-systemd
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    # TBD
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Dbus_jll"),
    Dependency("eudev"),
    Dependency("Glib_jll"),
    # Dependency("Libical_jll"),
    Dependency("Readline_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
