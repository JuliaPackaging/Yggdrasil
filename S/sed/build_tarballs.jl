# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sed"
version = v"4.8.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/sed/sed-4.8.tar.xz", "f79b0cfea71b37a8eeec8490db6c5f7ae7719c35587f21edb0617f370eeff633")
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
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("sed", :sed)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
