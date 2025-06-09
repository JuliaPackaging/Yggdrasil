using BinaryBuilder

# Collection of sources required to build Gettext
name = "Gettext"
version = v"0.25.0"

sources = [
    ArchiveSource("https://ftp.gnu.org/pub/gnu/gettext/gettext-$(version.major).$(version.minor).tar.xz",
                  "05240b29f5b0f422e5a4ef8e9b5f76d8fa059cc057693d2723cdb76f36a88ab0"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gettext-*/

export CFLAGS="-O2"
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"

if [[ "${target}" == *-mingw* ]]; then
    # Apply patch from https://lists.gnu.org/archive/html/bug-gettext/2020-07/msg00035.html
    #      ../woe32dll/.libs/libgettextsrc_la-c++format.o: In function `__static_initialization_and_destruction_0':
    #      /workspace/srcdir/gettext-0.21/gettext-tools/src/../woe32dll/../src/format.c:67: undefined reference to `__imp_formatstring_ruby'
    # atomic_patch -p1 ../patches/0001-build-Fix-build-failure-on-mingw-formatstring_ruby.patch
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
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgettextlib", "libgettextlib-$(version.major)"], :libgettext)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Libiconv_jll"),
    Dependency("XML2_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
