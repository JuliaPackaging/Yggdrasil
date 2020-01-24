# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "opusfile"
version = v"0.11.0"

# Collection of sources required to complete build
sources = [
    "https://downloads.xiph.org/releases/opus/opusfile-0.11.tar.gz" =>
    "74ce9b6cf4da103133e7b5c95df810ceb7195471e1162ed57af415fabf5603bf",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd opusfile-*
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
    MacOS(:x86_64)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libopusurl", :libopusfile),
    LibraryProduct("libopusfile", :libopusurl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    PackageSpec(name="Ogg_jll", uuid="e7412a2a-1a6e-54c0-be00-318e2571c051")
    PackageSpec(name="Opus_jll", uuid="91d4177d-7536-5919-b921-800302f37372")
    PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
