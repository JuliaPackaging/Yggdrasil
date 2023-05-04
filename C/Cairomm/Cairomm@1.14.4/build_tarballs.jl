# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Cairomm"
version = v"1.14.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.cairographics.org/releases/cairomm-$(version).tar.xz",
                  "4749d25a2b2ef67cc0c014caaf5c87fa46792fc4b3ede186fb0fc932d2055158")
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cairomm*/
atomic_patch -p1 ../patches/disable-quartz-aarch64-apple-darwin.patch
mkdir output && cd output/
meson --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

# armv6l is not supported by Cairo_jll yet
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

platforms = expand_cxxstring_abis(platforms; skip=Returns(false))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libcairomm-1", "libcairomm-1.0"], :libcairomm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Cairo_jll", uuid="83423d85-b0ee-5818-9007-b63ccbeb887a"), compat="1.16.1")
    Dependency(PackageSpec(name="libsigcpp_jll", uuid="8855df87-3ca1-5a3d-a68b-4f0ddc198ba8"), v"2.12.0"; compat="2")
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
