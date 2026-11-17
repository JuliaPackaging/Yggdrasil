using BinaryBuilder2

name = "Ncurses"
version = v"6.6.0"

sources = [
    ArchiveSource("https://ftpmirror.gnu.org/ncurses/ncurses-$(version.major).$(version.minor).tar.gz",
                  "355b4cbbed880b0381a04c46617b7656e362585d52e9cf84a67e2009b749ff11"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ncurses-*

# The build environment sets `TERMINFO`, which configure would take as the directory
# to install the terminfo database into, instead of `${prefix}/share/terminfo`.
unset TERMINFO

# Features that change the format of the compiled terminfo database, shared by
# the target build and the host `tic` below.
feature_args=(
    --enable-colorfgbg
    --enable-ext-colors
    --enable-ext-mouse
    --enable-widec
)

# `make install` compiles the terminfo database with a `tic` that runs on the build
# machine.  Build a static one from the same sources and configuration.
mkdir build-host
pushd build-host
CC="${HOST_CC}" CPP="${HOST_CC} -E" CXX="${HOST_CXX}" \
AR="${HOST_AR}" RANLIB="${HOST_RANLIB}" LD="${HOST_LD}" NM="${HOST_NM}" STRIP="${HOST_STRIP}" \
../configure --build=${MACHTYPE} --host=${MACHTYPE} \
    "${feature_args[@]}" \
    --enable-database \
    --without-shared \
    --with-normal \
    --without-ada \
    --without-cxx-binding \
    --without-debug \
    --without-manpages \
    --without-tests
make -j${nproc} -C include
make -j${nproc} -C ncurses libs
make -j${nproc} -C progs tic
export TIC="${PWD}/progs/tic"
popd

args=(
    "${feature_args[@]}"
    --disable-rpath
    --disable-static
    --enable-assertions
    --enable-database
    --enable-pc-files
    --enable-warnings
    --with-normal
    --with-shared
    --without-ada
    --without-cxx-binding
    --without-debug
    --without-manpages
    --without-tests
)

if [[ ${target} == *-darwin* ]]; then
    args+=(
        --disable-stripping
    )
elif [[ "${target}" == *-mingw* ]]; then
    args+=(
        --enable-sp-funcs
        --enable-term-driver
    )
    # Do not export multi-byte string functions.  They are defined in a system
    # library, and re-exporting them would give duplicate definitions.
    export LDFLAGS="-Wl,--exclude-symbols,mbrtowc:mbrlen:mbsrtowcs:wcsrtombs:mbtowc:wctomb"
fi

# Ncurses checks whether it is built on a "multi-user system" (a container isn't).
# If not, it ignores environment variables when running as root, which breaks the
# `TERMINFO_DIRS` setting done when the JLL is loaded.
export cf_cv_multiuser=yes

./configure --build=${MACHTYPE} --host=${target} --prefix=${prefix} --with-build-cc="${HOST_CC}" "${args[@]}"
make -j${nproc}
make install

if [[ "${target}" == *-mingw* ]]; then
    # Ensure we didn't put a copy of `mbrtowc` into our `libncursesw` library
    nm -A ${prefix}/lib/libncursesw.dll.a | grep -w 'mbrtowc$' && false
fi

# Remove duplicates that don't work on case-insensitive filesystems
rm -f  ${prefix}/share/terminfo/2/2621a
rm -rf ${prefix}/share/terminfo/a
rm -rf ${prefix}/share/terminfo/e
rm -f  ${prefix}/share/terminfo/h/hp2621a
rm -f  ${prefix}/share/terminfo/h/hp70092a
rm -rf ${prefix}/share/terminfo/l
rm -rf ${prefix}/share/terminfo/m
rm -rf ${prefix}/share/terminfo/n
rm -rf ${prefix}/share/terminfo/p
rm -rf ${prefix}/share/terminfo/q
rm -rf ${prefix}/share/terminfo/X

# Install pc files and fool packages looking for non-wide-character ncurses.
# Windows DLLs carry the ABI version in their name and live in `bin`.
abiver=""
shlibdir="${libdir}"
if [[ "${target}" == *-mingw* ]]; then
    abiver=6
    shlibdir="${bindir}"
fi
for lib in ncurses form panel menu; do
    install -Dm644 "misc/${lib}w.pc" "${prefix}/lib/pkgconfig/${lib}w.pc"
    ln -s "${lib}w.pc" "${prefix}/lib/pkgconfig/${lib}.pc"
    ln -s "lib${lib}w${abiver}.${dlext}" "${shlibdir}/lib${lib}${abiver}.${dlext}"
done
ln -s ncursesw ${includedir}/ncurses
"""

platforms = supported_platforms()

products = [
    LibraryProduct(["libform", "libform6"], :libform),
    LibraryProduct(["libmenu", "libmenu6"], :libmenu),
    LibraryProduct(["libncurses", "libncurses6"], :libncurses),
    LibraryProduct(["libncursesw", "libncursesw6"], :libncursesw),
    LibraryProduct(["libpanel", "libpanel6"], :libpanel),
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
