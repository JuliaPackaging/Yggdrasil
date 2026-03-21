# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LittleCMS"
version = v"2.17.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mm2/Little-CMS.git", "5176347635785e53ee5cee92328f76fda766ecc6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Little-CMS/
if [[ "${target}" == powerpc64le-* ]]; then
    autoreconf -vi
fi
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblcms2", :liblcms2),
    ExecutableProduct("psicc", :psicc),
    ExecutableProduct("transicc", :transicc),
    ExecutableProduct("linkicc", :linkicc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("JpegTurbo_jll"; compat="3.1.1"),
    Dependency("Libtiff_jll"; compat="4.7.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
