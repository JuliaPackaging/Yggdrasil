# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Pangomm"
version = v"2.46.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/pangomm/$(version.major).$(version.minor)/pangomm-$(version).tar.xz",
                  "410fe04d471a608f3f0273d3a17d840241d911ed0ff2c758a9859c66c6f24379")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pangomm*/
if [[ "${target}" == "${MACHTYPE}" ]]; then
    # Delete host libexpat.so to avoid confusion 
    rm /usr/lib/libexpat*
fi
mkdir output && cd output
meson --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson ..
ninja -j${nproc}
ninja install
"""

# These are the pltforms we will build for by default, unless further
# platforms are passed in on the command line

# These platforms are not supported by Cairo_jll/Pango_jll yet
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

platforms = expand_cxxstring_abis(platforms; skip=Returns(false))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libpangomm-1", "libpangomm-1.4"], :libpangomm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Cairomm_jll", uuid="af74c99f-f0eb-54aa-aecc-a10e8fc65c17"), compat="~1.14.4")
    Dependency(PackageSpec(name="Glibmm_jll", uuid="5d85a9da-21f7-5855-afec-cdc5039c46e8"), compat="~2.66.6")
    Dependency(PackageSpec(name="Pango_jll", uuid="36c8627f-9965-5494-a995-c6b170f724f3"), compat="^1.50.9")
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
