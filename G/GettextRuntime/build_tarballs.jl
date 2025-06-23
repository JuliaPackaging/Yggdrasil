using BinaryBuilder

# Collection of sources required to build GettextRuntime
name = "GettextRuntime"
version_string = "0.22.4"
version = VersionNumber(version_string)

sources = [
    ArchiveSource("https://ftp.gnu.org/pub/gnu/gettext/gettext-$(version_string).tar.xz",
                  "29217f1816ee2e777fa9a01f9956a14139c0c23cc1b20368f06b2888e8a34116"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gettext-*/gettext-runtime

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-static \
    --enable-relocatable \
    --with-libiconv-prefix=${prefix} \
    --with-included-gettext
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
    LibraryProduct("libintl", :libintl),
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
