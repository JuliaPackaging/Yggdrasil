# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenSlide"
version = v"3.4.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/openslide/openslide/releases/download/v3.4.1/openslide-3.4.1.tar.gz", "fed08fab8a9b1ded95a34e196652291127ebe392c11f9bc13d26e760295a102d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd openslide-3.4.1/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(!Sys.isapple, supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libopenslide", :libopenslide)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828"))
    Dependency(PackageSpec(name="OpenJpeg_jll", uuid="643b3616-a352-519d-856d-80112ee9badc"))
    Dependency(PackageSpec(name="gdk_pixbuf_jll", uuid="da03df04-f53b-5353-a52f-6a8b0620ced0"))
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"))
    Dependency(PackageSpec(name="SQLite_jll", uuid="76ed43ae-9a5d-5a62-8c75-30186b810ce8"))
    Dependency(PackageSpec(name="Cairo_jll", uuid="83423d85-b0ee-5818-9007-b63ccbeb887a"))
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"), v"2.59.0"; compat="2.59")
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
