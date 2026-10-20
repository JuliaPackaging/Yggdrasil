using BinaryBuilder

# Collection of sources required to build GettextRuntime
name = "GettextRuntime"
version_string = "1.0"
version = VersionNumber(version_string)

sources = [
    # <ftp.gnu.org> has a too-strict rate limit.
    ArchiveSource("https://ftpmirror.gnu.org/gettext/gettext-$(version_string).tar.xz",
                  "71132a3fb71e68245b8f2ac4e9e97137d3e5c02f415636eb508ae607bc01add7"),


    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gettext-*

# Reported as <https://savannah.gnu.org/bugs/?67987>
atomic_patch -p1 ../patches/progreloc.patch

cd gettext-runtime

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-static \
    --enable-relocatable \
    --with-libiconv-prefix=${prefix} \
    --with-included-libintl \
    am_cv_lib_iconv=yes \
    am_cv_func_iconv=yes
make -j${nproc}
make install

# Multiple licenses are required
cp ../COPYING toplevel-COPYING
cp intl/COPYING.LIB intl-COPYING.LIB
install_license COPYING toplevel-COPYING intl-COPYING.LIB
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libintl", "libgnuintl"], :libintl),
    LibraryProduct("libasprintf", :libasprintf),
    ExecutableProduct("gettext", :gettext),
    ExecutableProduct("ngettext", :ngettext),
    ExecutableProduct("envsubst", :envsubst),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
