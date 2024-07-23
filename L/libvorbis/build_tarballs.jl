# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libvorbis"
version = v"1.3.7"

# Collection of sources required to build libvorbis
sources = [
    ArchiveSource("https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-$(version).tar.xz",
                  "b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libvorbis-*

# Patch in explicit dependency on `stdint.h` to fix libogg
# This will be fixed in a future libogg release:
# https://github.com/xiph/ogg/commit/c8fca6b4a02d695b1ceea39b330d4406001c03ed
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/stdint.patch"

# Force `./configure` to repent from using `-ffast-math`
sed -ie 's/-ffast-math//g' ./configure

./configure --prefix=$prefix --host=$target --build=${MACHTYPE} --disable-static
make -j${nproc}
make install
# Remove large docs directory
rm -r "${prefix}/share/doc"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libvorbis", :libvorbis),
    LibraryProduct("libvorbisenc", :libvorbisenc),
    LibraryProduct("libvorbisfile", :libvorbisfile),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Ogg_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# rebuild counter: 1
