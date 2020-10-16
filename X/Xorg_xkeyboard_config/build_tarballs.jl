# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xkeyboard_config"
version = v"2.27"

# Collection of sources required to build xkeyboard_config
sources = [
    ArchiveSource("https://www.x.org/archive/individual/data/xkeyboard-config/xkeyboard-config-$(version.major).$(version.minor).tar.bz2",
                  "690daec8fea63526c07620c90e6f3f10aae34e94b6db6e30906173480721901f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xkeyboard-config-*
apk add libxslt
./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xproto_jll"),
    BuildDependency("Xorg_kbproto_jll"),
    Dependency("Xorg_xkbcomp_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
