# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "htslib"
version = v"1.10.2"


# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/samtools/htslib/releases/download/$(version)/htslib-$(version).tar.bz2",
                  "e3b543de2f71723830a1e0472cf5489ec27d0fbeb46b1103e14a11b7177d1939")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/htslib-*
export CPPFLAGS="-I${prefix}/include"
export CFLAGS="-I${prefix}/include"
export LDFLAGS=-L${libdir}
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install

# On Windows, product files are renamed so that BB can find them.
if [[ ${target} == *-mingw32 ]]; then
    # Add .exe extension to executables.
    for exefile in bgzip tabix htsfile; do
        mv "${bindir}/${exefile}" "${bindir}/${exefile}${exeext}"
    done
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# NOTE: Configuring i686-w64-mingw32 fails due to 'unable to find the recv()
# function' error. So we skip it for now.
platforms = [p for p in supported_platforms() if p != Platform("i686", "windows")]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libhts", "hts"], :libhts),
    ExecutableProduct("bgzip", :bgzip),
    ExecutableProduct("tabix", :tabix),
    ExecutableProduct("htsfile", :htsfile),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("Bzip2_jll"),
    Dependency("XZ_jll"),
    Dependency("LibCURL_jll"),
    Dependency("OpenSSL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
