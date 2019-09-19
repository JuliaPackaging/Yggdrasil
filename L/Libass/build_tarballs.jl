# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "libass"
version = v"0.14.0"
# Collection of sources required to build LibassBuilder
sources = [
    "https://github.com/libass/libass/releases/download/0.14.0/libass-0.14.0.tar.xz" =>
    "881f2382af48aead75b7a0e02e65d88c5ebd369fe46bc77d9270a94aa8fd38a2",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
apk add nasm
cd libass-0.14.0/
# Grumble-grumble apple grumble-grumble broken linkers...
if [[ ${target} == *-apple-* ]]; then
    export AR=/opt/${target}/bin/ar
fi
./configure --prefix=$prefix --host=$target --disable-require-system-font-provider
make -j${ncore}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libass", :libass),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "FreeType2_jll",
    "fribidi_jll",
    "Bzip2_jll",
    "Zlib_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
