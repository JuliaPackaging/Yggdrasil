# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sed"
version_string = "4.10"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/gnu/sed/sed-$(version_string).tar.xz",
                  "b8e72182b2ec96a3574e2998c47b7aaa64cc20ce000d8e9ac313cc07cecf28c7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sed-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc} SUBDIRS="po ."
make install SUBDIRS="po ."
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("sed", :sed)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
