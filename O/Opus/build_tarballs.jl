# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Opus"
version = v"1.3.1"

# Collection of sources required to build Opus
sources = [
    ArchiveSource("https://archive.mozilla.org/pub/opus/opus-$(version).tar.gz",
                  "65b58e1e25b2a114157014736a3d9dfeaad8d41be1c8179866f144a2fb44ff9d"),
]

version = v"1.3.3" # <--- This version number is a lie to build for experimental platforms

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/opus-*/

if [[ ${target} == *musl* ]]; then
    # On musl, disable stack protection (https://www.openwall.com/lists/musl/2018/09/11/2)
    STACK_PROTECTOR="--disable-stack-protector"
elif [[ "${target}" == *-mingw* ]]; then
    # Fix error
    #     /opt/x86_64-w64-mingw32/bin/../lib/gcc/x86_64-w64-mingw32/8.1.0/../../../../x86_64-w64-mingw32/bin/ld: src/opus_compare.o: in function `fread':
    #     /opt/x86_64-w64-mingw32/x86_64-w64-mingw32/sys-root/include/stdio.h:812: undefined reference to `__chk_fail'
    # See https://github.com/msys2/MINGW-packages/issues/5868#issuecomment-544107564
    export LDFLAGS="-lssp"
fi

./configure --prefix=$prefix --host=$target --build=${MACHTYPE} \
            --disable-static \
            --enable-custom-modes \
            ${STACK_PROTECTOR}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libopus", :libopus),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
