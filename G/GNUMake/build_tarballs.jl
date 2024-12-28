# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GNUMake"
version_string = "4.4.1"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/make/make-$(version_string).tar.gz",
                  "dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
# Really ugly straight translation of the build_w32.bat file here. Could probably still use make file
# but this is more or less a translation of the "official" install method.
script = raw"""
cd $WORKSPACE/srcdir/make*
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/make-4.3_undef-HAVE_STRUCT_DIRENT_D_TYPE.patch
if [[ "${target}" == *-mingw* ]]; then
    cp $WORKSPACE/srcdir/Makefile GNUmakefile
    mkdir -p ${prefix}/lib
    mkdir -p ${bindir}
    cp src/config.h.W32 src/config.h
    cp lib/glob.in.h lib/glob.h
    cp lib/fnmatch.in.h lib/fnmatch.h
    
    make -j${nproc}
else
    ./configure --build=${MACHTYPE} --prefix=$prefix --host=${target}
    make -j${nproc}
    make install
fi
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("make",:make)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
