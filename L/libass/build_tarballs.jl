# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "libass"
version = v"0.15.1"

# Collection of sources required to build libass
sources = [
    ArchiveSource("https://github.com/libass/libass/releases/download/$(version)/libass-$(version).tar.xz",
                  "1cdd39c9d007b06e737e7738004d7f38cf9b1e92843f37307b24e7ff63ab8e53"),
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
    Dependency("HarfBuzz_jll"; compat="2.8.1"),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
