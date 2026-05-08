using BinaryBuilder

name = "JpegTurbo"
upstream_version = "3.1.4.1"
version = v"3.1.5" # Needed to change version number to bump compat bounds, next time can go back to follow upstream

# Collection of sources required to build Ogg
sources = [
    # The release notes say that this is the official source tarball for this release
    ArchiveSource("https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/$(upstream_version)/libjpeg-turbo-$(upstream_version).tar.gz",
                  "ecae8008e2cc9ade2f2c1bb9d5e6d4fb73e7c433866a056bd82980741571a022"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libjpeg-turbo*

options=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
)

if [[ $target == riscv64-* ]]; then
    # Disable SIMD to avoid build error
    options+=(-DWITH_SIMD=OFF)
fi

cmake -Bbuild "${options[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libjpeg", :libjpeg),
    LibraryProduct("libturbojpeg", :libturbojpeg),
    ExecutableProduct("cjpeg", :cjpeg),
    ExecutableProduct("djpeg", :djpeg),
    ExecutableProduct("jpegtran", :jpegtran),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Avengers; ASSEMBLE!
    HostBuildDependency("YASM_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
