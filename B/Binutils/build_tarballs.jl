using BinaryBuilder

name = "Binutils"
version = v"2.45"

sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-$(version.major).$(version.minor).tar.xz",
                  "c50c0e7f9cb188980e2cc97e4537626b1672441815587f1eab69d2a1bfbef5d2"),
    DirectorySource("bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/binutils-*

# Don't use `ln` (hard links), use `cp` (copy) to "duplicate" installed files
sed -i 's/ ln / cp /' binutils/Makefile.am binutils/Makefile.in

./configure --prefix=${prefix} \
    --target=${target} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-dependency-tracking \
    --enable-deterministic-archives \
    --disable-werror \
    --disable-gprof \
    --disable-gprofng \
    --disable-gas \
    --disable-gold \
    --disable-ld \
    --enable-install-libbfd \
    --enable-install-libctf \
    --enable-install-libiberty \
    --enable-plugins \
    --enable-targets=${target} \
    --disable-nls \
    --enable-64-bit-bfd \
    --disable-static \
    --enable-shared \
    --with-system-zlib=no \
    --with-zstd=yes

make -j${nproc}
make install

# Install the `-fPIC` version of `libiberty.a` (which we built) but which isn't installed by default,
# overwriting the non-pic version which was installed
if test -f ${prefix}/lib64/libiberty.a; then
    install -Dvm 755 libiberty/pic/libiberty.a ${prefix}/lib64/libiberty.a
elif test -f ${prefix}/lib/libiberty.a; then
    install -Dvm 755 libiberty/pic/libiberty.a ${prefix}/lib/libiberty.a
else
    exit 1
fi
"""

platforms = supported_platforms(; exclude = p -> !(Sys.islinux(p) || Sys.isfreebsd(p)))

products = [
    ExecutableProduct("addr2line", :addr2line),
    ExecutableProduct("ar", :ar),
    # ExecutableProduct("as", :as),
    ExecutableProduct("c++filt", :cxxfilt),
    # ExecutableProduct("dwp", :dwp),
    ExecutableProduct("elfedit", :elfedit),
    # ExecutableProduct("gprof", :gprof),
    # ExecutableProduct("gprofng", :gprofng),
    # ExecutableProduct("ld", :ld),
    # ExecutableProduct("ld.bfd", Symbol("ld.bfd")),
    # ExecutableProduct("ld.gold", Symbol("ld.gold")),
    ExecutableProduct("nm", :nm),
    ExecutableProduct("objcopy", :objcopy),
    ExecutableProduct("objdump", :objdump),
    ExecutableProduct("ranlib", :ranlib),
    ExecutableProduct("readelf", :readelf),
    ExecutableProduct("size", :binutils_size),
    ExecutableProduct("strings", :strings),
    ExecutableProduct("strip", :binutils_strip),
    LibraryProduct("libbfd", :libbfd),
    LibraryProduct("libctf", :libctf),
    LibraryProduct("libopcodes", :libopcodes),
]

dependencies = [
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("Zstd_jll"; compat="1.5.7"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
