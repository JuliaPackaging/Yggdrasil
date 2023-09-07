using BinaryBuilder

# Collection of sources required to build Gettext
name = "Gettext"
version = v"0.22.0"

sources = [
    ArchiveSource("https://ftp.gnu.org/pub/gnu/gettext/gettext-$(version.major).$(version.minor).tar.xz",
                  "0e60393a47061567b46875b249b7d2788b092d6457d656145bb0e7e6a3e26d93"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gettext-*

export CFLAGS="-O2"
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"

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

# On Windows we see the build error
#     undefined reference to `close_used_without_requesting_gnulib_module_close'
# The respective discussion at
# <https://lists.gnu.org/r/bug-gettext/2023-06/msg00059.html> shows
# that cross-compiling for Windows with our setup isn't supported, and
# that there isn't any real effort by the maintainers to remedy this
# problem. We thus disable Windows.
filter!(!Sys.iswinsows, platforms)

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
