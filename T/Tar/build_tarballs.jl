# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Tar"
version = v"1.34"

# Collection of sources required to build tar
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/tar/tar-$(version.major).$(version.minor).tar.xz",
                  "63bebd26879c5e1eea4352f0d03c991f966aeb3ddeb3c7445c902568d5411d28"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tar-*/
export FORCE_UNSAFE_CONFIGURE=1
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = filter!(!Sys.iswindows, supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    ExecutableProduct("tar", :tar),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Attr_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
