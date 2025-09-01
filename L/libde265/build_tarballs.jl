using BinaryBuilder, Pkg

name = "libde265"
version = v"1.0.16"
ygg_build = 0  # NOTE: increment on rebuild of the same upstream version, reset on new libde265 version
ygg_version = VersionNumber(version.major, version.minor, 1_000 * version.patch + ygg_build)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/strukturag/libde265/releases/download/v$(version)/libde265-$(version).tar.gz",
                  "b92beb6b53c346db9a8fae968d686ab706240099cdd5aff87777362d668b0de7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libde265-*

mkdir build

args+=(-DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN)
args+=(-DCMAKE_INSTALL_PREFIX=$prefix)
args+=(-DCMAKE_BUILD_TYPE=RELEASE)

cmake -B build -S . "${args[@]}"

cmake --build build --parallel $nproc
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [LibraryProduct("libde265", :libde265)]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
)
