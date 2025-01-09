using BinaryBuilder

name = "Bzip2"
version = v"1.0.8"


# Collection of sources required to build bzip2
sources = [
    GitSource("git://sourceware.org/git/bzip2.git",
              "6a8690fc8d26c815e798c588f796eabe9d684cf0"),
]

# Bash recipe for building across all platforms
script = "VERSION=$(version)\n" * raw"""
cd $WORKSPACE/srcdir/bzip2*/

# Welp, auto-patching an include because otherwise win32/64 bzip2 won't cross-compile
sed -i 's/sys\\stat\.h/sys\/stat\.h/g' bzip2.c

# Override stubborn makevars
CFLAGS="-Wall -Winline -O2 -g -D_FILE_OFFSET_BITS=64 -fPIC"
OBJS="blocksort.o huffman.o crctable.o randtable.o compress.o decompress.o bzlib.o"
make CC=${CC} CFLAGS="${CFLAGS}" -j${nproc} ${OBJS}
make CC=${CC} CFLAGS="${CFLAGS}" PREFIX=${prefix} install

# Build dynamic library
if [[ "${target}" == *-darwin* ]]; then
    cc -shared -current_version "${VERSION}" -compatibility_version 1.0 -o "libbz2.${VERSION}.dylib" ${OBJS}
    install_name_tool -id libbz2.1.0.dylib "libbz2.${VERSION}.dylib"
    ln -s libbz2.${VERSION}.dylib libbz2.1.0.dylib
    ln -s libbz2.${VERSION}.dylib libbz2.1.dylib
    ln -s libbz2.${VERSION}.dylib libbz2.dylib
elif [[ "${target}" == *-mingw* ]]; then
    cc -shared -o libbz2-1.dll ${OBJS}
    ln -s libbz2-1.dll libbz2.dll
else
    cc -shared -Wl,-soname -Wl,libbz2.so.1.0 -o "libbz2.so.${VERSION}" ${OBJS}
    ln -s "libbz2.so.${VERSION}" libbz2.so.1.0
    ln -s "libbz2.so.${VERSION}" libbz2.so.1
    ln -s "libbz2.so.${VERSION}" libbz2.so
fi
mkdir -p ${libdir}
mv -v libbz2*.${dlext}* ${libdir}/.

# Add pkg-config file
mkdir -p ${prefix}/lib/pkgconfig
cat << EOF > $prefix/lib/pkgconfig/bzip2.pc
prefix=${prefix}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/$(basename ${libdir})
sharedlibdir=\${libdir}
includedir=\${prefix}/include

Name: bzip2
Description: bzip2 compression library
Version: ${VERSION}

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
dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Build trigger: 2
