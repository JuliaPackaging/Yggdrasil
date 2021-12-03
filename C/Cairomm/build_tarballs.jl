# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Cairomm"
version = v"1.16.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.cairographics.org/releases/cairomm-$(version).tar.xz",
                  "6f6060d8e98dd4b8acfee2295fddbdd38cf487c07c26aad8d1a83bb9bff4a2c6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cairomm*/
mkdir output && cd output/
meson --cross-file=${MESON_TARGET_TOOLCHAIN} ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libcairomm-$(version.major).$(version.minor)", "libcairomm-$(version.major)"], :libcariomm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libsigcpp_jll", uuid="8855df87-3ca1-5a3d-a68b-4f0ddc198ba8"))
    Dependency(PackageSpec(name="Cairo_jll", uuid="83423d85-b0ee-5818-9007-b63ccbeb887a"); compat=string(version))
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
