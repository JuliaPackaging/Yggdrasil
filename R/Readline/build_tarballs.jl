using BinaryBuilder2

name = "Readline"
version = v"8.3"

# Upstream readline 8.3 patches, starting from 001
patch_hashes = [
    "21f0a03106dbe697337cd25c70eb0edbaa2bdb6d595b45f83285cdd35bac84de",
    "e27364396ba9f6debf7cbaaf1a669e2b2854241ae07f7eca74ca8a8ba0c97472",
    "72dee13601ce38f6746eb15239999a7c56f8e1ff5eb1ec8153a1f213e4acdb29",
]
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/gnu/readline/readline-$(version.major).$(version.minor).tar.gz",
                  "fe5383204467828cd495ee8d1d3c037a7eba1389c22bc6a041f627976f9061cc"),
    [FileSource("https://ftpmirror.gnu.org/gnu/readline/readline-$(version.major).$(version.minor)-patches/readline$(version.major)$(version.minor)-$(lpad(n, 3, '0'))",
                hash) for (n, hash) in enumerate(patch_hashes)]...,
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/readline-*/

for patch in ${WORKSPACE}/srcdir/readline83-*; do
    atomic_patch -p0 ${patch}
done

# Declare `struct winsize` on Windows. We'll never actually use it.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-winsize.patch

export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${prefix}/lib"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-curses
# readline does not link its shared libraries against ncurses on its own
make -j${nproc} SHLIB_LIBS="-lncursesw"
make install
install_license COPYING
"""

platforms = supported_platforms()

products = [
    LibraryProduct(["libhistory", "libhistory8"], :libhistory),
    LibraryProduct(["libreadline", "libreadline8"], :libreadline),
]

target_dependencies = [
    JLLSource("Ncurses_jll"; version=v"6.6.2"),
]

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    target_dependencies,
    julia_compat = "1.6",
)
