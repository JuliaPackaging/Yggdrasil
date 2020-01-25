# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "opusfile"
version = v"0.11.0"

# Collection of sources required to complete build
sources = [
    "https://downloads.xiph.org/releases/opus/opusfile-0.11.tar.gz" =>
    "74ce9b6cf4da103133e7b5c95df810ceb7195471e1162ed57af415fabf5603bf",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd opusfile-*

if [[ "${target}" == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/no-openssl-wincert.patch"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-pic
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libopusurl", :libopusurl),
    LibraryProduct("libopusfile", :libopusfile)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    PackageSpec(name="Ogg_jll", uuid="e7412a2a-1a6e-54c0-be00-318e2571c051")
    PackageSpec(name="Opus_jll", uuid="91d4177d-7536-5919-b921-800302f37372")
    PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
