# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "FLAC"
version = v"1.3.3"

# Collection of sources required to build FLAC
sources = [
    ArchiveSource("https://ftp.osuosl.org/pub/xiph/releases/flac/flac-$(version).tar.xz",
                  "213e82bd716c9de6db2f98bcadbc4c24c7e2efe8c75939a1a84e28539c4e1748"),
    DirectorySource("./bundled"),
]

# This version number is falsely incremented to build for experimental platforms
version = v"1.3.4"

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/flac-*/

# Include patch for finding definition of `AT_HWCAP2` within the Linux
# kernel headers, rather than the glibc headers, sicne our glibc is too old
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/flac_linux_headers.patch"

if [[ "${target}" == *-mingw* ]]; then 
    # Fix error 
    #     .libs/metadata_iterators.o:metadata_iterators.c:(.text+0x106b): undefined reference to `__memset_chk'
    # See https://github.com/msys2/MINGW-packages/issues/5868#issuecomment-544107564 
    export LIBS="-lssp" 
fi

./configure --prefix=$prefix --host=$target  --build=${MACHTYPE}
make -j${nproc}
make install
install_license COPYING.Xiph
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libFLAC", :libflac),
    LibraryProduct("libFLAC++", :libflacpp),
    ExecutableProduct("metaflac", :metaflac),
    ExecutableProduct("flac", :flac)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Ogg_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
