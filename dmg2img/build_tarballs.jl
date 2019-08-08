using BinaryBuilder

# Collection of sources required to build Nettle
name = "dmg2img"
version = v"1.6.7"
sources = [
    "https://github.com/Lekensteyn/dmg2img.git" =>
    "f16f247d30f868e84f31e24792b4464488f1c009",
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
platforms = filter(p -> !isa(p, FreeBSD), platforms)
platforms = filter(p -> !isa(p, Windows), platforms)

# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "dmg2img", :dmg2img)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.3/build_Zlib.v1.2.11.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Bzip2-v1.0.6-2/build_Bzip2.v1.0.6.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/OpenSSL-v1.1.1%2Bc%2B0/build_OpenSSL.v1.1.1+c.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
