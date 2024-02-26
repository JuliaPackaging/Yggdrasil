using BinaryBuilder

name = "JpegTurbo"
version = v"3.0.2"

# Collection of sources required to build Ogg
sources = [
    # The release notes say that this is the official source tarball for this release
    ArchiveSource("https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/$(version)/libjpeg-turbo-$(version).tar.gz",
                  "c2ce515a78d91b09023773ef2770d6b0df77d674e144de80d63e0389b3a15ca6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libjpeg-turbo*/

mkdir build
cd build

cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" -DCMAKE_POSITION_INDEPENDENT_CODE=ON
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libjpeg", :libjpeg),
    LibraryProduct("libturbojpeg", :libturbojpeg),
    ExecutableProduct("cjpeg", :cjpeg),
    ExecutableProduct("djpeg", :djpeg),
    ExecutableProduct("jpegtran", :jpegtran),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Avengers; ASSEMBLE!
    HostBuildDependency("YASM_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
