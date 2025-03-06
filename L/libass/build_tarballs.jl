# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "libass"
version = v"0.15.2"

# Collection of sources required to build libass
sources = [
    ArchiveSource("https://github.com/libass/libass/releases/download/$(version)/libass-$(version).tar.xz",
                  "1be2df9c4485a57d78bb18c0a8ed157bc87a5a8dd48c661961c625cb112832fd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libass-*
apk add nasm
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-require-system-font-provider --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libass", :libass),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("FriBidi_jll"),
    Dependency("HarfBuzz_jll"; compat="8.3.1"),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
