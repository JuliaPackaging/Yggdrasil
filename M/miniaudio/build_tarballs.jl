# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "miniaudio"
version = v"0.11.25"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/mackron/miniaudio/archive/refs/tags/$(version).tar.gz", "b900edcffe979816e2560a0580b9b1216d674b4f17fbadeca8f777a7f8ab0274")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd miniaudio*
mkdir -p ${libdir}
cc -shared -fPIC -O2 -I. miniaudio.c -o ${libdir}/libminiaudio.${dlext} -lpthread -lm
ls -la ${libdir}
install_license LICENSE
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libminiaudio", :libminiaudio)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
