# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Gumbo"
version = v"0.13.2" # <-- This version number is a lie to build for experimental platforms

# Collection of sources required to complete build
# v0.13.2 is the last release, so we keep that version number.
sources = [
    # Build from the tag in the active upstream
    GitSource("https://codeberg.org/gumbo-parser/gumbo-parser.git", "322c54c178590ba42b8b04e8c0e4840595a1f717"),

    # Vendor Autoconf 2.72e only to run autoreconf
    ArchiveSource("https://alpha.gnu.org/gnu/autoconf/autoconf-2.72e.tar.gz",
                  "f3478d3b597d51f5d61596fb2f6f6aba49cdd974b4b05ff0bac57f56b5cfdb39"),
]

# Bash recipe for building across all platforms
# Build system now demands Autoconf ≥2.72
script = raw"""
set -eux

# Build Autoconf 2.72e for the host inside the container
cd ${WORKSPACE}/srcdir/autoconf-2.72e
./configure --prefix=/opt/autoconf272
make -j${nproc}
make install
export PATH=/opt/autoconf272/bin:${PATH}

# Regenerate and build gumbo
cd ${WORKSPACE}/srcdir/gumbo-parser
mkdir -p m4
./autogen.sh
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-dependency-tracking
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgumbo", :libgumbo)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")