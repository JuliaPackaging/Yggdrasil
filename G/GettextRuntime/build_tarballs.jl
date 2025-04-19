using BinaryBuilder

# Collection of sources required to build GettextRuntime
name = "GettextRuntime"
version = v"0.24.0"

sources = [
    ArchiveSource("https://ftp.gnu.org/pub/gnu/gettext/gettext-$(version.major).$(version.minor).tar.xz",
                  "e1620d518b26d7d3b16ac570e5018206e8b0d725fb65c02d048397718b5cf318"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gettext-*/
cd gettext-runtime

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-static \
    --enable-relocatable \
    --with-libiconv-prefix=${prefix} \
    --with-included-gettext

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
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
