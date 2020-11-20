using BinaryBuilder

# Collection of sources required to build Nettle
name = "dmg2img"
version = v"1.6.7"
sources = [
    GitSource("https://github.com/Lekensteyn/dmg2img.git", "f16f247d30f868e84f31e24792b4464488f1c009"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/dmg2img*/

make -j${nproc} CFLAGS="-O2 -Wall -I${prefix}/include" LDFLAGS="-L${prefix}/lib -lssl"
make install DESTDIR=${prefix}
mv ${prefix}/usr/bin/* ${prefix}/bin/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(!Sys.isfreebsd, platforms)
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("dmg2img", :dmg2img)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("Bzip2_jll"),
    Dependency("OpenSSL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
