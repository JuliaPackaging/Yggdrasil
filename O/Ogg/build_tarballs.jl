using BinaryBuilder

name = "Ogg"
version = v"1.3.5"

sources = [
    ArchiveSource("https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-$(version).tar.xz",
                  "c4d91be36fc8e54deae7575241e03f4211eb102afb3fc0775fbbc1b740016705"),
]

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
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libogg", :libogg),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
