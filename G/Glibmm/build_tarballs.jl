# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Glibmm"
version = v"2.68.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/glibmm/2.68/glibmm-2.68.1.tar.xz", "6664e27c9a9cca81c29e35687f49f2e0d173a2fc9e98c3428311f707db532f8c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
apk add doxygen graphviz libxslt
cd glibmm-2.68.1/
meson --cross-file=${MESON_TARGET_TOOLCHAIN} --libdir lib builddir .
cd builddir/
ninja
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libglibmm", :glibmm),
    LibraryProduct("libglibmm_generate_extra_defs", :glibmm_gen),
    LibraryProduct("libgiomm", :giomm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"))
    Dependency(PackageSpec(name="libsigcpp_jll", uuid="8855df87-3ca1-5a3d-a68b-4f0ddc198ba8"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
