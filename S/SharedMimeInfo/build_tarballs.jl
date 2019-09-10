# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SharedMimeInfo"
version = v"1.12"

sources = [
    "https://gitlab.freedesktop.org/xdg/shared-mime-info/uploads/80c7f1afbcad2769f38aeb9ba6317a51/shared-mime-info-$(version.major).$(version.minor).tar.xz" =>
    "18b2f0fe07ed0d6f81951a5fd5ece44de9c8aeb4dc5bb20d4f595f6cc6bd403e",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/shared-mime-info-*/
apk add intltool

./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("update-mime-database", :update_mime_database),
    FileProduct("share/locale", :locale_dir),
]

# Dependencies that must be installed before this package can be built
# Based on http://www.linuxfromscratch.org/blfs/view/8.3/general/shared-mime-info.html
dependencies = [
    "Glib_jll",
    "XML2_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.  We use GCC 8 because it is the only GCC version that links
# properly on powerpc64le.  Shocking, I know, but this is the world we live in.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
