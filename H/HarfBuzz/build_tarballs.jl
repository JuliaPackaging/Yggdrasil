# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HarfBuzz"
version = v"2.7.4"

# Collection of sources required to build Harfbuzz
sources = [
    ArchiveSource("https://github.com/harfbuzz/harfbuzz/releases/download/$(version)/harfbuzz-$(version).tar.xz",
                  "1316959c13d70d14443c68510129432a1e32f5e01a3526dec11b7834978809cb"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/harfbuzz-*/
atomic_patch -p1 ../patches/Remove-HB_ICU_STMT.patch
autoreconf -i -f
./configure --prefix=$prefix --host=$target \
    --with-gobject=yes \
    --with-graphite2=yes \
    --with-glib=yes \
    --with-freetype=yes \
    --with-cairo=yes \
    --enable-gtk-doc-html=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libharfbuzz-icu", :libharfbuzz_icu),
    LibraryProduct("libharfbuzz", :libharfbuzz),
    LibraryProduct("libharfbuzz-subset", :libharfbuzz_subset),
    LibraryProduct("libharfbuzz-gobject", :libharfbuzz_gobject),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Glib_jll"),
    Dependency("FreeType2_jll"),
    Dependency("Graphite2_jll"),
    Dependency("Libffi_jll"),
    Dependency("Gettext_jll"),
    Dependency("Fontconfig_jll"),
    Dependency("Cairo_jll"),
    Dependency(PackageSpec(; name="ICU_jll", version=v"68.2.0")),
    BuildDependency("Xorg_xorgproto_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5")

