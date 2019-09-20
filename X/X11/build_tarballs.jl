# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "X11"
version = v"1.6.8"

# Collection of sources required to build Pango
sources = [
    "https://www.x.org/archive//individual/lib/libX11-$(version).tar.bz2" =>
    "b289a845c189e251e0e884cc0f9269bbe97c238df3741e854ec4c17c21e473d5",

    # Protos
    "https://www.x.org/releases/individual/proto/xproto-7.0.31.tar.bz2" =>
    "c6f9747da0bd3a95f86b17fb8dd5e717c8f3ab7f0ece3ba1b247899ec1ef7747",

    "https://www.x.org/archive/individual/proto/xextproto-7.3.0.tar.bz2" =>
    "f3f4b23ac8db9c3a9e0d8edb591713f3d70ef9c3b175970dd8823dfc92aa5bb0",

    "https://www.x.org/archive/individual/proto/kbproto-1.0.7.tar.bz2" =>
    "f882210b76376e3fa006b11dbd890e56ec0942bc56e65d1249ff4af86f90b857",

    "https://www.x.org/archive/individual/proto/inputproto-2.3.2.tar.bz2" =>
    "893a6af55733262058a27b38eeb1edc733669f01d404e8581b167f03c03ef31d",

    "https://www.x.org/archive/individual/xcb/xcb-proto-1.13.tar.bz2" =>
    "7b98721e669be80284e9bbfeab02d2d0d54cd11172b72271e47a2fe875e2bde1",

    "https://www.x.org/archive/individual/proto/renderproto-0.11.1.tar.bz2" =>
    "06735a5b92b20759204e4751ecd6064a2ad8a6246bb65b3078b862a00def2537",

    "https://www.x.org/archive/individual/proto/randrproto-1.5.0.tar.bz2" =>
    "4c675533e79cd730997d232c8894b6692174dce58d3e207021b8f860be498468",

    "https://www.x.org/archive/individual/proto/fixesproto-5.0.tar.bz2" =>
    "ba2f3f31246bdd3f2a0acf8bd3b09ba99cab965c7fb2c2c92b7dc72870e424ce",

    "https://www.x.org/archive/individual/proto/damageproto-1.2.1.tar.bz2" =>
    "5c7c112e9b9ea8a9d5b019e5f17d481ae20f766cb7a4648360e7c1b46fc9fc5b",

    "https://www.x.org/archive/individual/proto/compositeproto-0.4.tar.bz2" =>
    "6013d1ca63b2b7540f6f99977090812b899852acfbd9df123b5ebaa911e30003",

    "https://www.x.org/archive/individual/proto/xineramaproto-1.2.1.tar.bz2" =>
    "977574bb3dc192ecd9c55f59f991ec1dff340be3e31392c95deff423da52485b",

    "https://www.x.org/archive/individual/proto/recordproto-1.14.2.tar.bz2" =>
    "a777548d2e92aa259f1528de3c4a36d15e07a4650d0976573a8e2ff5437e7370",

    "https://www.x.org/archive/individual/proto/xf86vidmodeproto-2.3.1.tar.bz2" =>
    "45d9499aa7b73203fd6b3505b0259624afed5c16b941bd04fcf123e5de698770",

    "https://www.x.org/archive/individual/proto/dri2proto-2.8.tar.bz2" =>
    "f9b55476def44fc7c459b2537d17dbc731e36ed5d416af7ca0b1e2e676f8aa04",

    "https://www.x.org/archive/individual/proto/dri3proto-1.0.tar.bz2" =>
    "01be49d70200518b9a6b297131f6cc71f4ea2de17436896af153226a774fc074",

    "https://www.x.org/archive/individual/proto/glproto-1.4.17.tar.bz2" =>
    "adaa94bded310a2bfcbb9deb4d751d965fcfe6fb3a2f6d242e2df2d6589dbe40",

    # Utils
    "https://www.x.org/archive/individual/util/util-macros-1.19.2.tar.bz2" =>
    "d7e43376ad220411499a79735020f9d145fdc159284867e99467e0d771f3e712",

    # Libs
    "https://www.x.org/archive/individual/lib/xtrans-1.4.0.tar.bz2" =>
    "377c4491593c417946efcd2c7600d1e62639f7a8bbca391887e2c4679807d773",

    "https://www.x.org/archive/individual/lib/libXau-1.0.9.tar.bz2" =>
    "ccf8cbf0dbf676faa2ea0a6d64bcc3b6746064722b606c8c52917ed00dcb73ec",

    "https://www.x.org/archive/individual/lib/libpthread-stubs-0.1.tar.bz2" =>
    "004dae11e11598584939d66d26a5ab9b48d08a00ca2d00ae8d38ee3ac7a15d65",

    "https://www.x.org/archive/individual/lib/libXext-1.3.4.tar.bz2" =>
    "59ad6fcce98deaecc14d39a672cf218ca37aba617c9a0f691cac3bcd28edf82b",

    "https://www.x.org/archive/individual/xcb/libxcb-1.13.tar.bz2" =>
    "188c8752193c50ff2dbe89db4554c63df2e26a2e47b0fa415a70918b5b851daa",

    "https://www.x.org/archive/individual/lib/libXrender-0.9.10.tar.bz2" =>
    "c06d5979f86e64cabbde57c223938db0b939dff49fdb5a793a1d3d0396650949",

    "https://www.x.org/archive/individual/lib/libXrandr-1.5.2.tar.bz2" =>
    "8aea0ebe403d62330bb741ed595b53741acf45033d3bda1792f1d4cc3daee023",

    "https://www.x.org/archive/individual/lib/libXfixes-5.0.3.tar.bz2" =>
    "de1cd33aff226e08cefd0e6759341c2c8e8c9faf8ce9ac6ec38d43e287b22ad6",

    "https://www.x.org/archive/individual/lib/libXi-1.7.10.tar.bz2" =>
    "36a30d8f6383a72e7ce060298b4b181fd298bc3a135c8e201b7ca847f5f81061",

    "https://www.x.org/archive/individual/lib/libXcursor-1.2.0.tar.bz2" =>
    "3ad3e9f8251094af6fe8cb4afcf63e28df504d46bfa5a5529db74a505d628782",

    "https://www.x.org/archive/individual/lib/libXdamage-1.1.5.tar.bz2" =>
    "b734068643cac3b5f3d2c8279dd366b5bf28c7219d9e9d8717e1383995e0ea45",

    "https://www.x.org/archive/individual/lib/libXcomposite-0.4.5.tar.bz2" =>
    "b3218a2c15bab8035d16810df5b8251ffc7132ff3aa70651a1fba0bfe9634e8f",

    "https://www.x.org/archive/individual/lib/libXinerama-1.1.4.tar.bz2" =>
    "0008dbd7ecf717e1e507eed1856ab0d9cf946d03201b85d5dcf61489bb02d720",

    "https://www.x.org/archive/individual/lib/libXtst-1.2.3.tar.bz2" =>
    "4655498a1b8e844e3d6f21f3b2c4e2b571effb5fd83199d428a6ba7ea4bf5204",

    "https://www.x.org/archive/individual/lib/libxshmfence-1.3.tar.bz2" =>
    "b884300d26a14961a076fbebc762a39831cb75f92bed5ccf9836345b459220c7",

    "https://www.x.org/archive/individual/lib/libXxf86vm-1.1.4.tar.bz2" =>
    "afee27f93c5f31c0ad582852c0fb36d50e4de7cd585fcf655e278a633d85cd57",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/

CPPFLAGS="-I${prefix}/include"

for dir in *proto-* util-macros-* xtrans-* libXau-* libpthread-stubs-* libxcb-* libX11-* libXext-* libXrender-* libXrandr-* libXfixes-* libXi-* libXcursor-* libXdamage-* libXcomposite-* libXinerama-* libXtst-* libxshmfence-* libXxf86vm-*; do
    cd "$dir"
    # When compiling for things like ppc64le, we need newer `config.sub` files
    update_configure_scripts

    ./configure --prefix=${prefix} --host=${target} --enable-malloc0returnsnull=no
    if [[ "${dir}" == libX11-* ]]; then
        # For some obscure reason, this Makefile may not get the value of CPPFLAGS
        sed -i "s?CPPFLAGS = ?CPPFLAGS = ${CPPFLAGS}?" src/util/Makefile
    fi
    make -j${nproc}
    make install
    cd ..
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if !isa(p, MacOS) && !isa(p, Windows)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libX11", :libX11),
    LibraryProduct("libX11-xcb", :libX11_xcb),
    LibraryProduct("libXau", :libXau),
    LibraryProduct("libxcb-composite", :libxcb_composite),
    LibraryProduct("libxcb-damage", :libxcb_damage),
    LibraryProduct("libxcb-dpms", :libxcb_dpms),
    LibraryProduct("libxcb-dri2", :libxcb_dri2),
    LibraryProduct("libxcb-dri3", :libxcb_dri3),
    LibraryProduct("libxcb-glx", :libxcb_glx),
    LibraryProduct("libxcb-present", :libxcb_present),
    LibraryProduct("libxcb-randr", :libxcb_randr),
    LibraryProduct("libxcb-record", :libxcb_record),
    LibraryProduct("libxcb-render", :libxcb_render),
    LibraryProduct("libxcb-res", :libxcb_res),
    LibraryProduct("libxcb-screensaver", :libxcb_screensaver),
    LibraryProduct("libxcb-shape", :libxcb_shape),
    LibraryProduct("libxcb-shm", :libxcb_shm),
    LibraryProduct("libxcb", :libxcb),
    LibraryProduct("libxcb-sync", :libxcb_sync),
    LibraryProduct("libxcb-xf86dri", :libxcb_xf86dri),
    LibraryProduct("libxcb-xfixes", :libxcb_xfixes),
    LibraryProduct("libxcb-xinerama", :libxcb_xinerama),
    LibraryProduct("libxcb-xinput", :libxcb_xinput),
    LibraryProduct("libxcb-xkb", :libxcb_xkb),
    LibraryProduct("libxcb-xtest", :libxcb_xtest),
    LibraryProduct("libxcb-xvmc", :libxcb_xvmc),
    LibraryProduct("libxcb-xv", :libxcb_xv),
    LibraryProduct("libXcomposite", :libXcomposite),
    LibraryProduct("libXcursor", :libXcursor),
    LibraryProduct("libXdamage", :libXdamage),
    LibraryProduct("libXext", :libXext),
    LibraryProduct("libXfixes", :libXfixes),
    LibraryProduct("libXinerama", :libXinerama),
    LibraryProduct("libXi", :libXi),
    LibraryProduct("libXrandr", :libXrandr),
    LibraryProduct("libXrender", :libXrender),
    LibraryProduct("libxshmfence", :libxshmfence),
    LibraryProduct("libXtst", :libXtst),

    # ppc64le doesn't build this as a shared library.  Why?
    #LibraryProduct("libXxf86vm", :libXxf86vm),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
