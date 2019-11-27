# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Mineos"
version = v"1.0"

# Collection of sources required to build Mineos
sources = [
    "https://github.com/anowacki/mineos.git" =>
    "e2558b486d7656ef112608a8776643da66dc87cf",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mineos
./configure --prefix=$prefix --host=$target --disable-doc
make
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
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_gcc_versions(platforms)

# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "simpledit", :simpledit),
    ExecutableProduct(prefix, "endi", :endi),
    ExecutableProduct(prefix, "eigcon", :eigcon),
    ExecutableProduct(prefix, "eigen2asc", :eigen2asc),
    ExecutableProduct(prefix, "green", :green),
    ExecutableProduct(prefix, "syndat", :syndat),
    ExecutableProduct(prefix, "minos_bran", :minos_bran),
    ExecutableProduct(prefix, "cucss2sac", :cucss2sac)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

