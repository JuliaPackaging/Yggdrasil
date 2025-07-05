using BinaryBuilder, Pkg

name = "libheif"
version = v"1.20.1"
ygg_build = 0  # NOTE: increment on rebuild of the same upstream version, reset on new  libheifversion
ygg_version = VersionNumber(version.major, version.minor, 1_000 * version.patch + ygg_build)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/strukturag/libheif/releases/download/v$(version)/libheif-$(version).tar.gz",
                  "55cc76b77c533151fc78ba58ef5ad18562e84da403ed749c3ae017abaf1e2090"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libheif-*

mkdir build

args+=(-DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN)
args+=(-DCMAKE_INSTALL_PREFIX=$prefix)
args+=(-DCMAKE_BUILD_TYPE=RELEASE)

args+=(-DWITH_HEADER_COMPRESSION=1)
args+=(-DWITH_EXAMPLES=0)

cmake -B build -S . "${args[@]}"

cmake --build build
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [LibraryProduct("libheif", :libheif)]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Dependency("OpenJpeg_jll"),  # examples
    # Dependency("Libtiff_jll"),  # examples
    Dependency("libavif_jll"),
    Dependency("libde265_jll"),
    # Dependency("libpng_jll"),  # examples
    Dependency("brotli_jll"),
    Dependency("LERC_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version = v"10"
)
