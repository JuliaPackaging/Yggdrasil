using BinaryBuilder

# Collection of sources required to build Gettext
name = "GettextTiny"
version = v"0.3.2"
sources = [
    ArchiveSource("https://ftp.barfooze.de/pub/sabotage/tarballs/gettext-tiny-$(version).tar.xz",
                  "a9a72cfa21853f7d249592a3c6f6d36f5117028e24573d092f9184ab72bbe187"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gettext-tiny*/

export LDFLAGS="-L${libdir}"

make LIBINTL=NONE
make LIBINTL=NONE DESTDIR=${prefix} prefix=/ install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Support for Windows is not ready yet.
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    ExecutableProduct("msgfmt", :msgfmt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
