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

    "https://www.x.org/archive/individual/lib/xtrans-1.4.0.tar.bz2" =>
    "377c4491593c417946efcd2c7600d1e62639f7a8bbca391887e2c4679807d773",

    # Libs
    "https://www.x.org/archive/individual/lib/libXau-1.0.9.tar.bz2" =>
    "ccf8cbf0dbf676faa2ea0a6d64bcc3b6746064722b606c8c52917ed00dcb73ec",

    "https://www.x.org/archive/individual/lib/libpthread-stubs-0.1.tar.bz2" =>
    "004dae11e11598584939d66d26a5ab9b48d08a00ca2d00ae8d38ee3ac7a15d65",

    "https://www.x.org/archive/individual/lib/libXext-1.3.4.tar.bz2" =>
    "59ad6fcce98deaecc14d39a672cf218ca37aba617c9a0f691cac3bcd28edf82b",

    "https://www.x.org/archive/individual/xcb/libxcb-1.13.tar.bz2" =>
    "188c8752193c50ff2dbe89db4554c63df2e26a2e47b0fa415a70918b5b851daa",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/

CPPFLAGS="-I${prefix}/include"
if [[ "${target}" == *-apple-* ]]; then
    # Work around for
    #     size too large (archive member extends past the end of the file)
    # error.
    RANLIB="/opt/${target}/bin/llvm-ranlib"
fi

for dir in *proto-* xtrans-* libXau-* libpthread-stubs-* libxcb-* libX11-* libXext-*; do
    cd "$dir"
    # When compiling for things like ppc64le, we need newer `config.sub` files
    update_configure_scripts

    if [[ "${dir}" == libX11-* ]] || [[ "${dir}" == libXext-* ]]; then
        # Elliot checked this on all platforms, so we can skip the test.
        EXTRA_OPTS="--enable-malloc0returnsnull=no"
    fi

    ./configure --prefix=${prefix} --host=${target} ${EXTRA_OPTS}
    if [[ "${dir}" == libX11-* ]]; then
        # For some obscure reason, this Makefile may not get the value of CPPFLAGS
        sed -i "s?CPPFLAGS = ?CPPFLAGS = ${CPPFLAGS}?" src/util/Makefile
    fi
    make -j${nproc}
    make install
    EXTRA_OPTS=""
    cd ..
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if !isa(p, MacOS) && !isa(p, Windows)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libX11", :libX11),
    LibraryProduct("libX11-xcb", :libX11_xcb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
