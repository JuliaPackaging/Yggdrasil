# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.

include("../common.jl")

version_string = "2.13"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://downloads.sourceforge.net/project/argtable/argtable/argtable-$(version_string)/argtable$(version.major)-$(version.minor).tar.gz",
        "8f77e8a7ced5301af6e22f47302fdbc3b1ff41f2b83c43c77ae5ca041771ddbf",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/argtable*
install_license COPYING
autoreconf -fvi
./configure --build=$MACHTYPE --host=$target --target=$target --prefix=$prefix
make -j${nproc}
make install
"""

# These are the platforms that we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude = Sys.iswindows)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [LibraryProduct("libargtable2", :libargtable2)]

# Build the tarballs, and possibly a `build.jl` as well.
build_argtable(version, sources, script, platforms, products)
