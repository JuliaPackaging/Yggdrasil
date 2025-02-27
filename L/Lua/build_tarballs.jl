using BinaryBuilder

name = "Lua"
version = v"5.4.7"
ygg_version = v"5.4.8" # version increment to pick up riscv

sources = [
    ArchiveSource("https://www.lua.org/ftp/lua-$(version).tar.gz",
                  "9fbf5e28ef86c69858f6d3d34eccc32e911c1a28b4120ff3e84aaa70cfbf1e30"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/lua-*

atomic_patch -p1 "${WORKSPACE}/srcdir/patches/src_Makefile.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/src_lauxlib.c.patch"

if [[ ${target} == *-apple-* ]]; then
    MAKE_TARGET=macosx
elif [[ ${target} == *-freebsd* ]]; then
    # NOTE: The FreeBSD ports build also uses the bsd instead of the freebsd target,
    # since it hard-codes fewer things, apparently
    MAKE_TARGET=bsd
elif [[ ${target} == *-mingw* ]]; then
    MAKE_TARGET=mingw
else
    MAKE_TARGET=linux
    export CPPFLAGS="-I${prefix}/include"
fi

# XXX: Work around Lua apparently not understanding its own Windows setup
if [[ ${target} == *-mingw* ]]; then
    TO_BIN="lua.exe luac.exe"
    TO_LIB="lua54.dll"
else
    TO_BIN="lua luac"
    TO_LIB="liblua.${dlext}"
fi

make -j${nproc} ${MAKE_TARGET} DLEXT="${dlext}"
make install INSTALL_TOP="${prefix}" INSTALL_LIB="${libdir}" TO_BIN="${TO_BIN}" TO_LIB="${TO_LIB}"

install_license "${WORKSPACE}/srcdir/LICENSE"
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("lua", :lua),
    ExecutableProduct("luac", :luac),
    LibraryProduct(["liblua", "lua54"], :liblua),
]

dependencies = [
    Dependency("Readline_jll"),
]

build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
