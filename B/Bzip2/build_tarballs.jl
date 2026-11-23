using BinaryBuilder2

name = "Bzip2"
version = v"1.0.9" # Building v1.0.8, version bump to pick up riscv


# Collection of sources required to build bzip2
sources = [
    GitSource("https://sourceware.org/git/bzip2.git",
              "6a8690fc8d26c815e798c588f796eabe9d684cf0";
              tag="bzip2-1.0.8"),
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
# On mingw the linker writes bzip2.exe / bzip2recover.exe, but `make install` copies the
# extension-less names, so build the programs and provide those names.
if [[ "${target}" == *-mingw* ]]; then
    make CC=${CC} CFLAGS="${CFLAGS}" bzip2 bzip2recover
    install -Dvm 755 bzip2.exe bzip2
    install -Dvm 755 bzip2recover.exe bzip2recover
fi
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
if [[ "${target}" == *-mingw* ]]; then
    # Windows looks for DLLs in bin/, not lib/.  Only the DLLs move: nothing here builds an
    # import library, and a `*.dll*` glob would also pick up a `.dll.a` if one ever appeared.
    mkdir -vp ${bindir}
    mv -v libbz2*.dll ${bindir}/.
else
    mkdir -vp ${libdir}
    mv -v libbz2*.${dlext}* ${libdir}/.
fi

install_license LICENSE

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

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    julia_compat = "1.6",
)
