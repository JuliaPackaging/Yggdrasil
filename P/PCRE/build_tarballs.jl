using BinaryBuilder

name = "PCRE"
version = v"8.44"

# Collection of sources required to build Pcre
sources = [
    ArchiveSource("https://ftp.pcre.org/pub/pcre/pcre-$(version.major).$(version.minor).tar.bz2",
                  "19108658b23b3ec5058edc9f66ac545ea19f9537234be1ec62b714c84399366d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pcre-*/
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-utf8 \
    --enable-unicode-properties \
    --disable-static
make -j${nproc} VERBOSE=1
make install VERBOSE=1
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libpcre", :libpcre)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
