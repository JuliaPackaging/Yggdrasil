using BinaryBuilder2

name = "Bzip2"
version = v"1.0.8"
ygg_version = v"1.0.9"  # version bump to pick up riscv


# Collection of sources required to build bzip2
sources = [
    GitSource("https://sourceware.org/git/bzip2.git",
              "6a8690fc8d26c815e798c588f796eabe9d684cf0";
              tag="bzip2-$(version)"),
]

# Bash recipe for building across all platforms
script = "VERSION=$(ygg_version)\n" * raw"""
cd $WORKSPACE/srcdir/bzip2*/

# Welp, auto-patching an include because otherwise win32/64 bzip2 won't cross-compile
sed -i 's/sys\\stat\.h/sys\/stat\.h/g' bzip2.c

# Override stubborn makevars
CFLAGS="-Wall -Winline -O2 -g -D_FILE_OFFSET_BITS=64 -fPIC"
OBJS="blocksort.o huffman.o crctable.o randtable.o compress.o decompress.o bzlib.o"
make CC=${CC} CFLAGS="${CFLAGS}" -j${nproc} ${OBJS}
make CC=${CC} CFLAGS="${CFLAGS}" bzip2 bzip2recover
# `make install` copies the programs by their extension-less names, but on mingw the linker
# writes bzip2.exe and bzip2recover.exe; `${exeext}` is empty elsewhere, so this is a no-op
# there.
for prog in bzip2 bzip2recover; do
    [[ "${prog}${exeext}" == "${prog}" ]] || install -vm 755 ${prog}${exeext} ${prog}
done
make CC=${CC} CFLAGS="${CFLAGS}" PREFIX=${prefix} install

# Build and install the dynamic library, with its symlinks.
if [[ "${target}" == *-darwin* ]]; then
    cc -shared -current_version "${VERSION}" -compatibility_version 1.0 -o "libbz2.${VERSION}.dylib" ${OBJS}
    install_name_tool -id libbz2.1.0.dylib "libbz2.${VERSION}.dylib"
    install -Dvm 755 "libbz2.${VERSION}.dylib" ${libdir}/"libbz2.${VERSION}.dylib"
    ln -sv libbz2.${VERSION}.dylib ${libdir}/libbz2.1.0.dylib
    ln -sv libbz2.${VERSION}.dylib ${libdir}/libbz2.1.dylib
    ln -sv libbz2.${VERSION}.dylib ${libdir}/libbz2.dylib
elif [[ "${target}" == *-mingw* ]]; then
    # BinaryBuilder2's ${libdir} is ${prefix}/lib on Windows too, but DLLs must be in ${bindir}
    cc -shared -o libbz2-1.dll ${OBJS}
    install -Dvm 755 libbz2-1.dll ${bindir}/libbz2-1.dll
    ln -sv libbz2-1.dll ${bindir}/libbz2.dll
else
    cc -shared -Wl,-soname -Wl,libbz2.so.1.0 -o "libbz2.so.${VERSION}" ${OBJS}
    install -Dvm 755 "libbz2.so.${VERSION}" ${libdir}/"libbz2.so.${VERSION}"
    ln -sv "libbz2.so.${VERSION}" ${libdir}/libbz2.so.1.0
    ln -sv "libbz2.so.${VERSION}" ${libdir}/libbz2.so.1
    ln -sv "libbz2.so.${VERSION}" ${libdir}/libbz2.so
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
    version_series = ygg_version,
    sources,
    script,
    platforms,
    products,
    julia_compat = "1.6",
)
