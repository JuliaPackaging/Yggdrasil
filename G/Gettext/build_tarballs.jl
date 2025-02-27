using BinaryBuilder

# Collection of sources required to build Gettext
name = "Gettext"
version_string = "0.22.5"
version = VersionNumber(version_string)

sources = [
    ArchiveSource("https://ftp.gnu.org/pub/gnu/gettext/gettext-$(version_string).tar.xz",
                  "fe10c37353213d78a5b83d48af231e005c4da84db5ce88037d88355938259640"),
]

# Bash recipe for building across all platforms
script = """
VERSION_MAJOR=$(version.major)
VERSION_MINOR=$(version.minor)
VERSION_PATCH=$(version.patch)
""" *
raw"""
cd $WORKSPACE/srcdir/gettext-*

export CFLAGS="-O2"
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"

if [[ "${target}" == *-mingw* ]]; then
    # Correct Windows build error:
    #    .libs/libgettextsrc_la-write-catalog.o:write-catalog.c:(.text+0x7bf):
    #    undefined reference to `close_used_without_requesting_gnulib_module_close':
    # See <https://github.com/NixOS/nixpkgs/pull/280197>
    sed -i "s/@GNULIB_CLOSE@/1/" */*/unistd.in.h
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

if [[ "${target}" == *-mingw* ]]; then
    # Rename Windows library
    mv -v "${libdir}/libgettextlib-${VERSION_MAJOR}-${VERSION_MINOR}-${VERSION_PATCH}.${dlext}" "${libdir}/libgettextlib-${VERSION_MAJOR}.${dlext}"
fi
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
    Dependency("XML2_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
