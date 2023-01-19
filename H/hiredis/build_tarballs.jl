# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "hiredis"
version = v"1.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/redis/hiredis.git", "c14775b4e48334e0262c9f168887578f4a368b5d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hiredis/
make -j${nproc} USE_SSL=1 PREFIX="${prefix}" LIBRARY_PATH=$(basename "${libdir}") install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=!Sys.islinux)


# The products that we will ensure are always built
products = [
    LibraryProduct("libhiredis", :hiredis),
    LibraryProduct("libhiredis_ssl", :hiredis_ssl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
