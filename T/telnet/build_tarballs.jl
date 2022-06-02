# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "telnet"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/inetutils/inetutils-2.2.tar.xz", "d547f69172df73afef691a0f7886280fd781acea28def4ff4b4b212086a89d80")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd inetutils-2.2/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} -disable-ifconfig     --disable-hostname --disable-logger --disable-rcp     --disable-rexec --disable-rlogin --disable-rsh     --disable-tftp --disable-traceroute --disable-inetd     --disable-rexecd --disable-syslogd --disable-tftpd
make -j
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("telnet", :telnet)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Ncurses_jll", uuid="68e3532b-a499-55ff-9963-d1c0c0748b3a"))
    Dependency(PackageSpec(name="Libgcrypt_jll", uuid="d4300ac3-e22c-5743-9152-c294e39db1e4"))
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
