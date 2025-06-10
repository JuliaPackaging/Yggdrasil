# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sed"
version_string = "4.9"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/sed/sed-$(version_string).tar.xz",
                  "6e226b732e1cd739464ad6862bd1a1aba42d7982922da7a53519631d24975181"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sed-*
if [[ "${target}" == *-mingw* ]]; then
    # Fix error
    #    sed/sed-compile.o: In function `sprintf':
    #    /opt/x86_64-w64-mingw32/x86_64-w64-mingw32/sys-root/include/stdio.h:366: undefined reference to `__chk_fail'
    # See https://github.com/msys2/MINGW-packages/issues/5868#issuecomment-544107564
    export LIBS="-lssp"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc} SUBDIRS="po ."
make install SUBDIRS="po ."
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("sed", :sed)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
