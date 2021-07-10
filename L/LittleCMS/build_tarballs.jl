# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LittleCMS"
version = v"2.12.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/mm2/Little-CMS/releases/download/lcms$(version.major).$(version.minor)/lcms2-$(version.major).$(version.minor).tar.gz",
                  "18663985e864100455ac3e507625c438c3710354d85e5cbb7cd4043e11fe10f5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lcms2*/
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
platforms = supported_platforms(; experimental=true)

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
    Dependency("Libtiff_jll"; compat="4.3.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
