# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibMPDec"
version = v"4.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-$(version).tar.gz",
                  "96d33abb4bb0070c7be0fed4246cd38416188325f820468214471938545b1ac8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpdecimal-*

# configure adds its release flags, -std=c99 and -DNDEBUG, only for compilers
# it knows by name, not for `cc`. GCC 4.8 defaults to gnu90, which rejects
# declarations in for loops.
export CFLAGS="-std=gnu99 -DNDEBUG"
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-cxx \
    --disable-doc \
    --disable-static
make -j${nproc}
make install
install_license COPYRIGHT.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    # libmpdec++ isn't built, since nothing needs it yet.
    LibraryProduct("libmpdec", :libmpdec)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
