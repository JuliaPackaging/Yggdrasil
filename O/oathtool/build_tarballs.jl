# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oathtool"
version = v"2.6.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://download.savannah.nongnu.org/releases/oath-toolkit/oath-toolkit-2.6.2.tar.gz", "b03446fa4b549af5ebe4d35d7aba51163442d255660558cd861ebce536824aa0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/oath-toolkit-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64)
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("oathtool", :oathtool)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
