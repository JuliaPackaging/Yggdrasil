# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "tg"
version = v"0.7.3"

# Collection of sources required to build Libtiff
sources = [
    GitSource("https://github.com/tidwall/tg.git",
              "9464d05791814fa6005b1075570c7c501b37bf2a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tg
mkdir -p ${libdir}
${CC} -shared -o ${libdir}/libtg.${dlext} -fPIC -O3 tg.c
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Don't build on 32 bit platforms, since the library does not build there
# TODO: patch the library for 32 bit if necessary?  But I doubt it.
# platforms = filter!(platforms) do platform
#     !(nbits(platform) == 32)
# end

# The products that we will ensure are always built
products = [
    LibraryProduct("libtg", :libtg),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
