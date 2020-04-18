# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LittleCMS"
version = v"2.9.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://downloads.sourceforge.net/lcms/lcms2-2.9.tar.gz", "48c6fdf98396fa245ed86e622028caf49b96fa22f3e5734f853f806fbc8e7d20")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lcms2-2.9/
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
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
