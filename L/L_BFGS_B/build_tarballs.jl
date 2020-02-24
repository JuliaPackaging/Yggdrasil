# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "L_BFGS_B"
version = v"3.0.1"

# Collection of sources required to build LBFGSB
sources = [
    ArchiveSource("http://users.iems.northwestern.edu/~nocedal/Software/Lbfgsb.3.0.tar.gz",
                  "f5b9a1c8c30ff6bcc8df9b5d5738145f4cbe4c7eadec629220e808dcf0e54720"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Lbfgsb.*/
patch -p0 < $WORKSPACE/srcdir/patches/lbfgsb.patch
mkdir -p "${libdir}"
FFLAGS="-O3 -fPIC -shared -Wall -fbounds-check -Wno-uninitialized"
${FC} ${LDFLAGS} ${FFLAGS} lbfgsb.f linpack.f blas.f timer.f -o "${libdir}/liblbfgsb.${dlext}"
install_license License.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("liblbfgsb", :liblbfgsb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
