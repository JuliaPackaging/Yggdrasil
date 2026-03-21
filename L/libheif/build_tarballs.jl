using BinaryBuilder, Pkg

name = "libheif"
version = v"1.20.2"
ygg_build = 0  # NOTE: increment on rebuild of the same upstream version, reset on new libheifversion
ygg_version = VersionNumber(version.major, version.minor, 1_000 * version.patch + ygg_build)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/strukturag/libheif.git",
              "35dad50a9145332a7bfdf1ff6aef6801fb613d68"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libheif

mkdir build

args+=(-DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN)
args+=(-DCMAKE_INSTALL_PREFIX=$prefix)
args+=(-DCMAKE_BUILD_TYPE=RELEASE)

args+=(-DWITH_HEADER_COMPRESSION=1)
args+=(-DWITH_EXAMPLES=0)
args+=(-DBUILD_TESTING=0)  # error: 'uncaught_exceptions' is unavailable: introduced in macOS 10.12

cmake -B build -S . "${args[@]}"

cmake --build build --parallel $nproc
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
    Dependency("libde265_jll"),
    Dependency("libavif_jll"),
    # Dependency("libpng_jll"),  # examples
    Dependency("brotli_jll"),
    Dependency("LERC_jll"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version = v"9"  # needs CXX20 - build errors on gcc8
)
