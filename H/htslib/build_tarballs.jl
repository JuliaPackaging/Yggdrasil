# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "htslib"
version = v"1.10.2"

# Collection of sources required to complete build
sources = [
    "https://github.com/samtools/htslib/releases/download/$(version)/htslib-$(version).tar.bz2" =>
        "e3b543de2f71723830a1e0472cf5489ec27d0fbeb46b1103e14a11b7177d1939",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/htslib-*
./configure \
    CFLAGS=-I${prefix}/include CPPFLAGS=-I${prefix}/include LDFLAGS=-L${prefix}/lib \
    --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install

# On Windows, product files are renamed so that BB can find them.
if [[ ${target} == *-mingw32 ]]; then
    # Rename a versioned DLL file.
    mv ${prefix}/bin/hts-*.dll ${prefix}/bin/libhts.dll
    # Add .exe extension to executables.
    for exefile in bgzip tabix htsfile; do
        mv ${prefix}/bin/${exefile} ${prefix}/bin/${exefile}.exe
    done
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# NOTE: Configuring i686-w64-mingw32 fails due to 'unable to find the recv()
# function' error. So we skip it for now.
platforms = [p for p in supported_platforms() if p != Windows(:i686)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libhts", :libhts),
    ExecutableProduct("bgzip", :bgzip),
    ExecutableProduct("tabix", :tabix),
    ExecutableProduct("htsfile", :htsfile),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Zlib_jll",
    "Bzip2_jll",
    "XZ_jll",
    "LibCURL_jll",
    "OpenSSL_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
