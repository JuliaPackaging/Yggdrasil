# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ATKmm"
version = v"2.36.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/atkmm/$(version.major).$(version.minor)/atkmm-$(version).tar.xz",
                  "e11324bfed1b6e330a02db25cecc145dca03fb0dff47f0710c85e317687da458")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/atkmm*/
mkdir output && cd output/
meson --cross-file=${MESON_TARGET_TOOLCHAIN} ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libatkmm-$(version.major).$(version.minor)", "libatkmm-$(version.major)"], :libatkmm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="ATK_jll", uuid="7b86fcea-f67b-53e1-809c-8f1719c154e8"); compat=string(version))
    Dependency(PackageSpec(name="Glibmm_jll", uuid="5d85a9da-21f7-5855-afec-cdc5039c46e8"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
