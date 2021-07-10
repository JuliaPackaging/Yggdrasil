# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenJpeg"
version = v"2.4.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/uclouvain/openjpeg/archive/v$(version)/openjpeg-$(version).tar.gz",
                  "8702ba68b442657f11aaeb2b338443ca8d5fb95b0d845757968a7be31ef7f16d"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openjpeg-*/
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_STATIC_LIBS=OFF
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libopenjp2", :libopenjp2),
    ExecutableProduct("opj_decompress", :opj_decompress),
    ExecutableProduct("opj_dump", :opj_dump),
    ExecutableProduct("opj_compress", :opj_compress)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="LittleCMS_jll", uuid="d3a379c0-f9a3-5b72-a4c0-6bf4d2e8af0f"))
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
