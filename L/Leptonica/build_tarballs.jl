# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Leptonica"
version = v"1.82.0"

# Collection of sources required to build Leptonica
sources = [
    ArchiveSource("https://github.com/DanBloomberg/leptonica/releases/download/$(version)/leptonica-$(version).tar.gz",
                  "155302ee914668c27b6fe3ca9ff2da63b245f6d62f3061c8f27563774b8ae2d6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/leptonica*/
export CPPFLAGS="-I${includedir}"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license leptonica-license.txt
# Get rid of libtool files
rm ${prefix}/lib/liblept*.la
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblept", :liblept),
    ExecutableProduct("convertfilestopdf", :convertfilestopdf),
    ExecutableProduct("convertfilestops", :convertfilestops),
    ExecutableProduct("convertformat", :convertformat),
    ExecutableProduct("convertsegfilestopdf", :convertsegfilestopdf),
    ExecutableProduct("convertsegfilestops", :convertsegfilestops),
    ExecutableProduct("converttopdf", :converttopdf),
    ExecutableProduct("converttops", :converttops),
    ExecutableProduct("fileinfo", :fileinfo),
    ExecutableProduct("imagetops", :imagetops),
    ExecutableProduct("xtractprotos", :xtractprotos),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Giflib_jll", uuid="59f7168a-df46-5410-90c8-f2779963d0ec")),
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8")),
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f")),
    Dependency("Libtiff_jll"; compat="4.3.0"),
    Dependency(PackageSpec(name="libwebp_jll", uuid="c5f90fcd-3b7e-5836-afba-fc50a0988cb2")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    # Leptonica has a runtime check on the minor version of OpenJpeg, because why not:
    # https://github.com/DanBloomberg/leptonica/blob/68d2cc15b955192f65772689d258a6d10dba52f5/src/jp2kio.c#L268-L272
    Dependency("OpenJpeg_jll"; compat="~2.4.0"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
