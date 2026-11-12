# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Ncurses"
version = v"6.6.0"

# Collection of sources required to build Ncurses
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/pub/gnu/ncurses/ncurses-$(version.major).$(version.minor).tar.gz",
                  "355b4cbbed880b0381a04c46617b7656e362585d52e9cf84a67e2009b749ff11"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ncurses-*

args=(
    --disable-rpath
    --disable-static
    --enable-assertions
    --enable-colorfgbg
    --enable-database
    --enable-ext-colors
    --enable-ext-mouse
    --enable-pc-files
    --enable-warnings
    --enable-widec
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
    # Do not export multi-byte string functions.
    # These functions are defined in a system library, and if we not re-export them,
    # there would be duplicate definitions.
    export LDFLAGS="-Wl,--exclude-symbols,mbrtowc:mbrlen:mbsrtowcs:wcsrtombs:mbtowc:wctomb"
fi

# Ncurses check whether we're building on a "multi-user system". (We're
# not, since we're building in a container.) If not, it disables access
# to environment variables when running as root (i.e. usually when
# running in a container). This breaks our `TERMINFO_DIRS` mechanism
# below.
export cf_cv_multiuser=yes

./configure --build=${MACHTYPE} --host=${target} --prefix=${prefix} "${args[@]}"
make -j${nproc}
make install

if [[ "${target}" == *-mingw* ]]; then
    # Ensure we didn't put a copy of `mbrtowc` into our `libncursesw` library
    ${target}-nm -A /workspace/destdir/lib/libncursesw.dll.a | grep -w 'mbrtowc$' && false
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

# Install pc files and fool packages looking for non-wide-character ncurses
for lib in ncurses form panel menu; do
    if [[ "${target}" == *-mingw* ]]; then
        # O Windows, Windows, wherefore art thou Windows?
        abiver=6
    fi
    install -Dm644 "misc/${lib}w.pc" "${prefix}/lib/pkgconfig/${lib}w.pc"
    ln -s "${lib}w.pc" "${prefix}/lib/pkgconfig/${lib}.pc"
    ln -s "lib${lib}w${abiver}.${dlext}" "${libdir}/lib${lib}${abiver}.${dlext}"
done
ln -s ncursesw ${includedir}/ncurses
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libform", "libform6"], :libform),
    LibraryProduct(["libmenu", "libmenu6"], :libmenu),
    LibraryProduct(["libncurses", "libncurses6"], :libncurses),
    LibraryProduct(["libncursesw", "libncursesw6"], :libncursesw),
    LibraryProduct(["libpanel", "libpanel6"], :libpanel),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We need to run the native "tic" program
    HostBuildDependency(PackageSpec(; name="Ncurses_jll", version="6.5.1")),
]

init_block = raw"""
if Sys.isunix()
    path = joinpath(artifact_dir, "share", "terminfo")
    old = get(ENV, "TERMINFO_DIRS", nothing)
    if old === nothing
        ENV["TERMINFO_DIRS"] = path
    else
        ENV["TERMINFO_DIRS"] = old * ":" * path
    end
end
"""

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", init_block)
