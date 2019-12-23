# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tmux"
version = v"3.0.0-a"

# Collection of sources required to complete build
sources = [
    "https://github.com/tmux/tmux/releases/download/3.0a/tmux-3.0a.tar.gz" =>
    "4ad1df28b4afa969e59c08061b45082fdc49ff512f30fc8e43217d7b0e5f8db9",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tmux-*/
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
    ExecutableProduct("tmux", :tmux)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    PackageSpec(name="libevent_jll", uuid="1080aeaf-3a6a-583e-a51c-c537b09f60ec")
    PackageSpec(name="Ncurses_jll", uuid="68e3532b-a499-55ff-9963-d1c0c0748b3a")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

