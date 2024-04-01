# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "YASM"
version = v"1.3.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.tortall.net/projects/yasm/releases/yasm-$(version).tar.gz", "3dce6601b495f5b3d45b59f7d2492a340ee7e84b5beca17e48f862502bd5603f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/yasm-*
autoreconf -f -i
export CCLD_FOR_BUILD="${CC_FOR_BUILD}"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} ac_cv_header_stdc=yes
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("yasm", :yasm),
    ExecutableProduct("ytasm", :ytasm),
    ExecutableProduct("vsyasm", :vsyasm)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
