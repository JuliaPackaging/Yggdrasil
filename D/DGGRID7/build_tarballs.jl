# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DGGRID7"
version = v"0.9.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/allixender/DGGRID.git", "0dabdfd3f8fd6ac27626064a94c483e610d578bb")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd DGGRID/src/
make
if [ -f apps/dggrid/dggrid.exe ]; then cp apps/dggrid/dggrid.exe /workspace/destdir/bin/; else cp apps/dggrid/dggrid /workspace/destdir/bin/; fi
exit
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
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("dggrid", :dggrid)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GDAL_jll", uuid="a7073274-a066-55f0-b90d-d619367d196c"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")
