# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "BlueZ"
version = v"5.54.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.kernel.org/pub/linux/bluetooth/bluez-$(version.major).$(version.minor).tar.xz", "68cdab9e63e8832b130d5979dc8c96fdb087b31278f342874d992af3e56656dc")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd bluez-*
# Hint to find libstc++, required to link against C++ libs when using C compiler
if [[ "${target}" == *-linux-* ]]; then
    if [[ "${nbits}" == 32 ]]; then
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib";
    else
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64";
    fi;
fi
# linux/if_alg doesn't seem to work; prevent configure from finding it
sed -i -e "s~ linux/if_alg.h~~" configure.ac 
autoconf
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-systemd --enable-library
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms())


# The products that we will ensure are always built
products = [
    ExecutableProduct("btmon", :btmon),
    ExecutableProduct("l2ping", :l2ping),
    ExecutableProduct("hid2hci", :hid2hci, "lib/udev"),
    ExecutableProduct("l2test", :l2test),
    ExecutableProduct("bccmd", :bccmd),
    ExecutableProduct("btattach", :btattach),
    ExecutableProduct("hex2hcd", :hex2hcd),
    ExecutableProduct("bluetoothd", :bluetoothd, "libexec/bluetooth"),
    ExecutableProduct("bluemoon", :bluemoon),
    ExecutableProduct("rctest", :rctest),
    ExecutableProduct("bluetooth", :bluetooth, "lib/cups/backend"),
    ExecutableProduct("mpris-proxy", :mpris_proxy),
    ExecutableProduct("obexd", :obexd, "libexec/bluetooth"),
    ExecutableProduct("bluetoothctl", :bluetoothctl),
    LibraryProduct("libbluetooth", :libbluetooth),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Dbus_jll", uuid="ee1fde0b-3d02-5ea6-8484-8dfef6360eab"))
    Dependency(PackageSpec(name="eudev_jll", uuid="35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"))
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"); compat="2.28")
    Dependency(PackageSpec(name="Libical_jll", uuid="bce108ef-3f60-5dd0-bcd6-e13a096cb796"))
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
