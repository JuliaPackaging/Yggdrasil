# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenJpeg"
version = v"2.5.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/uclouvain/openjpeg.git",
              "210a8a5690d0da66f02d49420d7176a21ef409dc"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openjpeg/
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_STATIC_LIBS=OFF
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libopenjp2", :libopenjp2),
    ExecutableProduct("opj_decompress", :opj_decompress),
    ExecutableProduct("opj_dump", :opj_dump),
    ExecutableProduct("opj_compress", :opj_compress)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LittleCMS_jll"; compat="2.15.0")
    Dependency("libpng_jll"; compat="1.6.38")
    Dependency("Libtiff_jll"; compat="4.5.1")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
