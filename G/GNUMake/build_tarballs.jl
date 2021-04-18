# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GNUMake"
version = v"4.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/make/make-4.3.tar.gz", "e05fdde47c5f7ca45cb697e973894ff4f5d79e13b750ed57d7b66d8defc78e19"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
# Really ugly straight translation of the build_w32.bat file here. Could probably still use make file
# but this is more or less a translation of the "official" install method.
script = raw"""
cd $WORKSPACE/srcdir/make-4.3
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/make-4.3_undef-HAVE_STRUCT_DIRENT_D_TYPE.patch
if [[ "${target}" == *-mingw* ]]; then
    cp $WORKSPACE/srcdir/Makefile GNUmakefile
    mkdir ${prefix}/lib
    mkdir ${prefix}/bin
    cp src/config.h.W32 src/config.h
    cp lib/glob.in.h lib/glob.h
    cp lib/fnmatch.in.h lib/fnmatch.h
    
    make -j${nproc}
    make install
else
    ./configure --build=${MACHTYPE} --prefix=$prefix --host=${target}
    make -j${nproc}
    make install
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("make",:make)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
