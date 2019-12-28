# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bmon"
version = v"4.0.0"

# Collection of sources required to complete build
sources = [
    "https://github.com/tgraf/bmon/releases/download/v4.0/bmon-4.0.tar.gz" =>
    "02fdc312b8ceeb5786b28bf905f54328f414040ff42f45c83007f24b76cc9f7a",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bmon-*/
export CFLAGS=-I$prefix/include
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license LICENSE.*
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
    MacOS(:x86_64)
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("bmon", :bmon)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    PackageSpec(name="Ncurses_jll", uuid="68e3532b-a499-55ff-9963-d1c0c0748b3a")
    PackageSpec(name="libnl_jll", uuid="7c700954-19d3-5208-81e2-8fa5fe7c0bd8")
    PackageSpec(name="libconfuse_jll", uuid="9f03c2a6-2865-5578-ae11-af8a29163b66")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
