# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "UDUNITS"
version = v"2.2.28"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://artifacts.unidata.ucar.edu/repository/downloads-udunits/udunits-$(version).tar.gz", "590baec83161a3fd62c00efa66f6113cec8a7c461e3f61a5182167e0cc5d579e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd udunits-2.2.28/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make all
make all install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libudunits2", :libudunits2),
    ExecutableProduct("udunits2", :udunits2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Expat_jll", uuid="2e619515-83b5-522b-bb60-26c02a35a201"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
