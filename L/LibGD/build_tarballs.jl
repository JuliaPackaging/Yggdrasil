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

mkdir build && cd build

cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_PNG=1 \
    -DENABLE_JPEG=1 \
    -DENABLE_TIFF=1 \
    -DENABLE_WEBP=1 \
    -DENABLE_XPM=0 \
    -DENABLE_GD_FORMATS=1 \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..

cmake --build . -j${nproc} --target install
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
    Dependency("Libtiff_jll"; compat="~4.5.1"),
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid = "c4d99508-4286-5418-9131-c86396af500b")),
    Dependency(PackageSpec(name="Xorg_libXpm_jll", uuid = "1a3ddb2d-74e3-57f3-a27b-e9b16291b4f2")),
    Dependency(PackageSpec(name="Libiconv_jll", uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531")),
    Dependency("libwebp_jll"; compat="1.2.4"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
