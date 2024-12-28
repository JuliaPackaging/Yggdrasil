# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LittleCMS"
version = v"2.16.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mm2/Little-CMS.git", "453bafeb85b4ef96498866b7a8eadcc74dff9223")
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
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"); compat="3.0.1")
    Dependency("Libtiff_jll"; compat="4.5.1")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
