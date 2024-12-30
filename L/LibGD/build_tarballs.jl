using BinaryBuilder, Pkg

name = "LibGD"
version = v"2.3.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libgd/libgd.git",
              "b5319a41286107b53daa0e08e402aa1819764bdc")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgd

./bootstrap.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-png --with-jpeg --with-tiff --with-webp --with-zlib

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
    # TODO: v4.3.0 is available, use that next time
    Dependency("Libtiff_jll"; compat="4.5.1"),
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid = "c4d99508-4286-5418-9131-c86396af500b")),
    Dependency(PackageSpec(name="Libiconv_jll", uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531")),
    Dependency("libwebp_jll"; compat="1.2.4"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
