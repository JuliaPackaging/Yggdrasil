# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libgraphicsmagic"
version = v"1.3.36"

# Collection of sources required to complete build
sources = [
    ArchiveSource("ftp://ftp.icm.edu.pl/pub/unix/graphics/GraphicsMagick/1.3/GraphicsMagick-1.3.36.tar.gz", "1e6723c48c4abbb31197fadf8396b2d579d97e197123edc70a4f057f0533d563")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd GraphicsMagick-1.3.36/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(!Sys.iswindows, supported_platforms(; experimental=true))
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libGraphicsMagickWand", :libGraphicsMagicWand),
    LibraryProduct("libGraphicsMagick++", :libGraphicsMagicPlusPlus),
    LibraryProduct("libGraphicsMagick", :libGraphicsMagic),
    ExecutableProduct("gm", :gm)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
