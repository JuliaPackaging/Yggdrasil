using BinaryBuilder

name = "PCRE"
version = v"8.45"

# Collection of sources required to build Pcre
sources = [
    ArchiveSource("https://sourceforge.net/projects/pcre/files/pcre/$(version.major).$(version.minor)/pcre-$(version.major).$(version.minor).tar.bz2",
                  "4dae6fdcd2bb0bb6c37b5f97c33c2be954da743985369cddac3546e3218bffb8"),
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
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libpcre", :libpcre)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6")
