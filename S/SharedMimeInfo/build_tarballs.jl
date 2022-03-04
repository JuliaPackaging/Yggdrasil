# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SharedMimeInfo"
version = v"1.15"

sources = [
    ArchiveSource("https://gitlab.freedesktop.org/xdg/shared-mime-info/uploads/b27eb88e4155d8fccb8bb3cd12025d5b/shared-mime-info-$(version.major).$(version.minor).tar.xz",
                  "f482b027437c99e53b81037a9843fccd549243fd52145d016e9c7174a4f5db90"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/shared-mime-info-*/
apk add itstool

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-update-mimedb
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
    Dependency("Glib_jll", v"2.59.0"; compat="2.59.0"),
    Dependency("XML2_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.  We use GCC 8 because it is the only GCC version that links
# properly on powerpc64le.  Shocking, I know, but this is the world we live in.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
