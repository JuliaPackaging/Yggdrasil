# Note that this script can be used independently, without requiring a checkout of the whole Yggdrasil repository
using BinaryBuilder, Pkg

name = "xlsxio"
version = v"0.2.36"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/brechtsanders/xlsxio.git", "a9016eb2eb46dcd613a68fcfcd1002b5adf64ae9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xlsxio*/
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED:BOOL=ON \
    -DBUILD_STATIC:BOOL=OFF \
    -DBUILD_TOOLS:BOOL=ON \
    -DBUILD_EXAMPLES:BOOL=OFF \
    -DWITH_LIBZIP:BOOL=ON \
    -DEXPAT_INCLUDE_DIR=${includedir} \
    -DEXPAT_LIBRARY=${libdir}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libxlsxio_read", :libxlsxio_read),
    LibraryProduct("libxlsxio_write", :libxlsxio_write),
    ExecutableProduct("xlsxio_xlsx2csv", :xlsxio_xlsx2csv),
    ExecutableProduct("xlsxio_csv2xlsx", :xlsxio_csv2xlsx),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Expat_jll"; compat="~2.5"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

