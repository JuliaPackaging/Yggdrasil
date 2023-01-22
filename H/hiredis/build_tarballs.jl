# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "hiredis"
version = v"1.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/redis/hiredis.git",
              "c14775b4e48334e0262c9f168887578f4a368b5d"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hiredis/
# Link `libhiredis_ssl` to `libhiredis`, no clue how this is supposed to work otherwise.
atomic_patch -p1 ../patches/link-hiredis-ssl.patch
make -j${nproc} \
    USE_SSL=1 \
    PREFIX="${prefix}" \
    OPENSSL_PREFIX="${prefix}" \
    LIBRARY_PATH=$(basename "${libdir}") \
    DYLIBSUFFIX="${dlext}" \
    install
# Remove static libraries
rm ${prefix}/lib/libhiredis*.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct("libhiredis", :libhiredis),
    LibraryProduct("libhiredis_ssl", :libhiredis_ssl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="1.1.13"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
