# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Htop"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    "http://hisham.hm/htop/releases/2.2.0/htop-2.2.0.tar.gz" =>
    "d9d6826f10ce3887950d709b53ee1d8c1849a70fa38e91d5896ad8cbc6ba3c57",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/htop-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install

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
    ExecutableProduct("htop", :htop)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "PackageSpec(
  name = Ncurses_jll
  uuid = 68e3532b-a499-55ff-9963-d1c0c0748b3a
  version = *
)",

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

