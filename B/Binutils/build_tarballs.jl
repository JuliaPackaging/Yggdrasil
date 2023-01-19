using BinaryBuilder

name = "Binutils"
version = v"2.39"

sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-$(version.major).$(version.minor).tar.xz", "645c25f563b8adc0a81dbd6a41cffbf4d37083a382e02d5d3df4f65c09516d00"),
    DirectorySource("$(@__DIR__)/bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/binutils-*/

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
    --enable-shared

make -j${nproc}
make install
"""

platforms = supported_platforms(; exclude=!Sys.islinux)

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

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
