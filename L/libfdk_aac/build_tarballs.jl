# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libfdk_aac"
version = v"2.0.3"
ygg_version = v"2.0.4"

# Collection of sources required to build libfdk
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-$(version).tar.gz",
                  "829b6b89eef382409cda6857fd82af84fabb63417b08ede9ea7a553f811cb79e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fdk-aac-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
install_license NOTICE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libfdk-aac", :libfdk)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6")
