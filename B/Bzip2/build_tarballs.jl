using BinaryBuilder

name = "Bzip2"
version = v"1.0.6"

# Collection of sources required to build bzip2
sources = [
    "https://github.com/enthought/bzip2-1.0.6.git" =>
    "288acf97a15d558f96c24c89f578b724d6e06b0c"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bzip2-*/

# Welp, auto-patching an include because otherwise win32/64 bzip2 won't cross-compile
sed -i 's/sys\\stat\.h/sys\/stat\.h/g' bzip2.c

# Override stubborn makevars
CFLAGS="-Wall -Winline -O2 -g -D_FILE_OFFSET_BITS=64 -fPIC"
OBJS="blocksort.o huffman.o crctable.o randtable.o compress.o decompress.o bzlib.o"
make CFLAGS="${CFLAGS}" -j${nproc} ${OBJS}
make CFLAGS="${CFLAGS}" PREFIX=${prefix} install

# Build dynamic library
if [[ "${target}" == *-darwin* ]]; then
    $CC -shared -current_version 1.0.6 -compatibility_version 1.0 -o libbz2.1.0.6.dylib $LDFLAGS $OBJS
    ln -s libbz2.1.0.6.dylib libbz2.1.0.dylib
    ln -s libbz2.1.0.6.dylib libbz2.1.dylib
    ln -s libbz2.1.0.6.dylib libbz2.dylib
    mv libbz2*.dylib ${prefix}/lib/
elif [[ "${target}" == *-mingw* ]]; then
    $CC -shared -o libbz2-1.dll $LDFLAGS $OBJS
    ln -s libbz2-1.dll libbz2.dll
    mv libbz2*.dll ${prefix}/bin/
else
    $CC -shared -Wl,-soname -Wl,libbz2.so.1.0 -o libbz2.so.1.0.6 $LDFLAGS $OBJS
    ln -s libbz2.so.1.0.6 libbz2.so.1.0
    ln -s libbz2.so.1.0.6 libbz2.so.1
    ln -s libbz2.so.1.0.6 libbz2.so
    mv libbz2.so* ${prefix}/lib/
fi

# Add pkg-config file
mkdir -p ${prefix}/lib/pkgconfig
cat << EOF > $prefix/lib/pkgconfig/bzip2.pc
prefix=${prefix}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
sharedlibdir=\${libdir}
includedir=\${prefix}/include

Name: bzip2
Description: bzip2 compression library
Version: 1.0.6

Requires:
Libs: -L\${libdir} -L\${sharedlibdir} -lbz2
Cflags: -I\${includedir}
EOF
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libbz2", :libbzip2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
