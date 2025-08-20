# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXdmcp"
version = v"1.1.5"
# We bumped the version number because we built for riscv64
ygg_version = v"1.1.6"

# Collection of sources required to build libXdmcp
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXdmcp-$(version).tar.xz",
                  "d8a5222828c3adab70adf69a5583f1d32eb5ece04304f7f8392b6a353aa2228c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXdmcp-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->!(Sys.islinux(p) || Sys.isfreebsd(p)))

products = [
    LibraryProduct("libXdmcp", :libXdmcp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6")
