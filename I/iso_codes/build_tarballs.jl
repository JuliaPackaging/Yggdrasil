# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "iso_codes"
version = v"4.15.0"

# the git tag used for versioning has changed format
if version < v"4.8"
    if version < v"4.5" && version.patch == 0
        tag = "iso-codes-$(version.major).$(version.minor)"
    else
        tag = "iso-codes-$version"
    end
else
    tag = "v$version"
end

# Collection of sources required to build iso-codes
sources = [
    ArchiveSource("https://salsa.debian.org/iso-codes-team/iso-codes/-/archive/$tag/iso-codes-$tag.tar.bz2",
                  "5aed05f5053080fe55c3fb47f46677691efb59dfb215bd41484a391a7c4df9c5"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/iso-codes-*/
apk update
apk add gettext
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = Product[
    FileProduct("share/iso-codes", :iso_codes_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
