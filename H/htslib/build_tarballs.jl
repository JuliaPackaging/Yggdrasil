# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "htslib"
version = v"1.14"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/samtools/htslib/releases/download/$(version.major).$(version.minor)/htslib-$(version.major).$(version.minor).tar.bz2",
                  "ed221b8f52f4812f810eebe0cc56cd8355a5c9d21c62d142ac05ad0da147935f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/htslib-*
export CPPFLAGS="-I${includedir}"
export LDFLAGS=-L${libdir}
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install

# Delete static library
rm "${prefix}/lib/libhts.a"

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
platforms = supported_platforms(; experimental=true, exclude=Sys.iswindows)

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
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("XZ_jll"),
    Dependency("LibCURL_jll"),
    Dependency("OpenSSL_jll"; compat="1.1.10"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
