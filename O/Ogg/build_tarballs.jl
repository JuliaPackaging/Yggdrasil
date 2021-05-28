using BinaryBuilder

name = "Ogg"
version = v"1.3.4"

sources = [
    ArchiveSource("https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-$(version).tar.xz",
                  "c163bc12bc300c401b6aa35907ac682671ea376f13ae0969a220f7ddf71893fe"),
]

version = v"1.3.5" # <-- This version number is a lie to build for experimental platforms

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libogg-*/

# Don't let `configure` use `-ffast-math` ANYWHERE
sed -i.bak -e 's/-ffast-math//g' ./configure
./configure --prefix=$prefix --host=${target} --build=${MACHTYPE}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libogg", :libogg),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
