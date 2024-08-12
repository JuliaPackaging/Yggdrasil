# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Glibmm"
version = v"2.66.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/glibmm/$(version.major).$(version.minor)/glibmm-$(version).tar.xz",
                  "5358742598181e5351d7bf8da072bf93e6dd5f178d27640d4e462bc8f14e152f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glibmm*/
apk add glib-dev
mkdir builddir
cd builddir
meson --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(); skip=Returns(false))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libglibmm-2.4", "libglibmm-2", "libglibmm"], :libglibmm),
    LibraryProduct(["libgiomm-2.4", "libgiomm-2", "libgiomm"], :libgiomm),
    LibraryProduct(["libglibmm_generate_extra_defs-2.4",
                    "libglibmm_generate_extra_defs-2",
                    "libglibmm_generate_extra_defs"], :libglibmm_generate_extra_defs),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"), v"2.74.0"; compat="^2.61.2")
    Dependency(PackageSpec(name="libsigcpp_jll", uuid="8855df87-3ca1-5a3d-a68b-4f0ddc198ba8"), v"2.12.0"; compat="2")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
