using BinaryBuilder

# Collection of sources required to build Gettext
name = "Gettext"
version_string = "1.0"
version = VersionNumber(version_string)

sources = [
    # <ftp.gnu.org> has a too-strict rate limit.
    # <ftpmirror.gnu.org> does not have gettext-1.0. (yet?)
    # ArchiveSource("https://ftpmirror.gnu.org/pub/gnu/gettext/gettext-$(version_string).tar.xz",
    #               "71132a3fb71e68245b8f2ac4e9e97137d3e5c02f415636eb508ae607bc01add7"),
    ArchiveSource("https://mirror.csclub.uwaterloo.ca/gnu/gettext/gettext-$(version_string).tar.xz",
                  "71132a3fb71e68245b8f2ac4e9e97137d3e5c02f415636eb508ae607bc01add7"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gettext-*

export CFLAGS="-O2"
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"

# Reported as <https://savannah.gnu.org/bugs/?67987>
atomic_patch -p1 ../patches/progreloc.patch

if [[ "${target}" == *-mingw* ]]; then
    # Do not export multi-byte string functions.
    # These functions are defined in a system library, and if we not re-export them,
    # there would be duplicate definitions.
    export LDFLAGS="-Wl,--exclude-symbols,mbrtowc:mbrlen:mbsrtowcs:wcsrtombs:mbtowc:wctomb"
fi

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-static \
    --enable-relocatable \
    --with-libiconv-prefix=${prefix} \
    am_cv_lib_iconv=yes \
    am_cv_func_iconv=yes
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgettextlib", "libgettextlib-$(version.major)"], :libgettext)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Libiconv_jll"),
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency("XML2_jll"; compat="~2.13.6"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
