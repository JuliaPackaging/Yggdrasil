using BinaryBuilder

# Collection of sources required to build Gettext
name = "Help2man"
version = v"1.48.1"
sources = [
               ArchiveSource("ftp://ftp.gnu.org/gnu/help2man/help2man-1.48.1.tar.xz",
                              "de8a74740bd058646567b92ab4ecdeb9da9f1a07cc7c4f607a3c14dd38d10799"),
               ]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/help2man*/
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
                FileProduct("help2man", :help2man),

                ]

# Dependencies that must be installed before this package can be built
dependencies = [
                  ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)