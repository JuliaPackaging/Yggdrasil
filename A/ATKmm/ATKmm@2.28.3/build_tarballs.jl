# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ATKmm"
version = v"2.28.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/atkmm/$(version.major).$(version.minor)/atkmm-$(version).tar.xz",
                  "7c2088b486a909be8da2b18304e56c5f90884d1343c8da7367ea5cd3258b9969")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/atkmm*/
mkdir output && cd output/
meson --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(); skip=Returns(false))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libatkmm-1.6", "libatkmm-1", "libatkmm"], :libatkmm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # This version targets the libsigc++-2.0 ABI, which Glibmm uses up to version 2.66
    Dependency(PackageSpec(name="ATK_jll", uuid="7b86fcea-f67b-53e1-809c-8f1719c154e8"); compat="^2.38.0")
    Dependency(PackageSpec(name="Glibmm_jll", uuid="5d85a9da-21f7-5855-afec-cdc5039c46e8"); compat="~2.66.6")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
