# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "htslib"
version_string = "1.19.1"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/samtools/htslib/releases/download/$(version_string)/htslib-$(version_string).tar.bz2",
                  "222d74d3574fb67b158c6988c980eeaaba8a0656f5e4ffb76b5fa57f035933ec")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/htslib-*
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
platforms = supported_platforms(; exclude=Sys.iswindows)

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
    Dependency("XZ_jll"; compat="5.2.5"),
    Dependency("LibCURL_jll"; compat="7.73,8"),
    Dependency("OpenSSL_jll"; compat="3.0.8"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
