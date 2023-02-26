# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mold"
version = v"1.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/rui314/mold.git", "1f55e40a8a967894816d6366bcc3d08de74c84b4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mold/
make -j${nproc}
make install PREFIX="${prefix}" BINDIR="${bindir}" LIBDIR="${libdir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter!(Sys.islinux, supported_platforms()))


# The products that we will ensure are always built
products = [
    ExecutableProduct("mold", :mold)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="1.1.10")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10")
