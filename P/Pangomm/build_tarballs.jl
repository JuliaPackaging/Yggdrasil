# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Pangomm"
version = v"2.49.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/pangomm/$(version.major).$(version.minor)/pangomm-$(version).tar.xz",
                  "a2272883152618fddea016a62f50eb23b9b056ab3c08f3b64422591e6a507bd5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pangomm*/
if [[ "${target}" == "${MACHTYPE}" ]]; then
    # Delete host libexpat.so to avoid confusion 
    rm /usr/lib/libexpat*
fi
mkdir output && cd output
meson --cross-file=${MESON_TARGET_TOOLCHAIN} ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))
# We don't have armv6l Pango at the moment
filter!(p -> arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libpangomm-$(version.major)", "libpangomm-$(version.major).48"], :libpangomm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Cairomm_jll", uuid="af74c99f-f0eb-54aa-aecc-a10e8fc65c17"); compat="~1.16.1")
    Dependency(PackageSpec(name="Glibmm_jll", uuid="5d85a9da-21f7-5855-afec-cdc5039c46e8"); compat="~2.68.1")
    Dependency(PackageSpec(name="Pango_jll", uuid="36c8627f-9965-5494-a995-c6b170f724f3"); compat="1.47.0")
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
