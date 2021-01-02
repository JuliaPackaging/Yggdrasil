using BinaryBuilder, Pkg

name = "LibGD"
version = v"2.3.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libgd/libgd/releases/download/gd-$(version)/libgd-$(version).tar.gz",
                  "32590e361a1ea6c93915d2448ab0041792c11bae7b18ee812514fe08b2c6a342")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgd-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
# For some reasons (something must be off in the configure script), on some
# platforms the build system tries to use iconv but without adding the `-liconv`
# flag.  Give a hint to make to use the right flag everywhere
make -j${nproc} LIBICONV="-liconv" LTLIBICONV="-liconv"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("pngtogd2", :pngtogd2),
    ExecutableProduct("webpng", :webpng),
    ExecutableProduct("pngtogd", :pngtogd),
    ExecutableProduct("gdtopng", :gdtopng),
    ExecutableProduct("gdcmpgif", :gdcmpgif),
    ExecutableProduct("gd2topng", :gd2topng),
    ExecutableProduct("gdparttopng", :gdparttopng),
    ExecutableProduct("gd2copypal", :gd2copypal),
    ExecutableProduct("gd2togif", :gd2togif),
    ExecutableProduct("giftogd2", :giftogd2),
    LibraryProduct("libgd", :libgd),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f")),
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828")),
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid = "c4d99508-4286-5418-9131-c86396af500b")),
    Dependency(PackageSpec(name="Xorg_libXpm_jll", uuid = "1a3ddb2d-74e3-57f3-a27b-e9b16291b4f2")),
    Dependency(PackageSpec(name="Libiconv_jll", uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531")),
    Dependency(PackageSpec(name="libwebp_jll", uuid = "c5f90fcd-3b7e-5836-afba-fc50a0988cb2")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
