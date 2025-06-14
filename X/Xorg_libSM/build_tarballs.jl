# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libSM"
version = v"1.2.6"

# Collection of sources required to build libSM
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libSM-$(version).tar.xz",
                  "be7c0abdb15cbfd29ac62573c1c82e877f9d4047ad15321e7ea97d1e43d835be"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libSM-*/
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->Sys.isapple(p) || Sys.iswindows(p))

products = [
    LibraryProduct("libSM", :libSM),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xtrans_jll"),
    BuildDependency("Xorg_xproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_libICE_jll"; compat="1.1.2"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
