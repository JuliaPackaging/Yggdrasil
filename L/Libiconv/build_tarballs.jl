using BinaryBuilder2

name = "Libiconv"
version = v"1.18.0"

tarball = "libiconv-$(version.major).$(version.minor).tar.gz"
sources = [
    ArchiveSource(["https://ftp.gnu.org/pub/gnu/libiconv/$(tarball)",
                   "https://ftpmirror.gnu.org/libiconv/$(tarball)",
                   "https://mirrors.kernel.org/gnu/libiconv/$(tarball)",
                   "https://ftp.fau.de/gnu/libiconv/$(tarball)"],
                  "3b08f5f4f9b4eb82f151a7040bfd6fe6c6fb922efe4b1659c66ea933276965e8"),
]

script = "VERSION=$(version.major).$(version.minor)\n" * raw"""
cd ${WORKSPACE}/srcdir/libiconv-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-static --enable-extra-encodings
make -j${nproc}
make install

# libiconv doesn't install a pkg-config file.  `libdir` is `lib` on Windows too, since
# that is where the import libraries the linker needs are.
mkdir -p "${prefix}/lib/pkgconfig"
cat << EOF > "${prefix}/lib/pkgconfig/iconv.pc"
prefix=\${pcfiledir}/../..
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
sharedlibdir=\${libdir}
includedir=\${prefix}/include

Name: iconv
Description: libiconv
URL: https://www.gnu.org/software/libiconv/
Version: ${VERSION}

Requires:
Libs: -L\${libdir} -liconv
Cflags: -I\${includedir}
EOF
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libcharset", :libcharset),
    LibraryProduct("libiconv", :libiconv),
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
