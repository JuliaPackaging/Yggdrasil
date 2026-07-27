using BinaryBuilder

name = "JpegTurbo"
version = v"3.2.0"

# Collection of sources required to build Ogg
sources = [
    # The release notes say that this is the official source tarball for this release
    ArchiveSource("https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/$(version)/libjpeg-turbo-$(version).tar.gz",
                  "6f30092cef9fb839779646608f4ee14ae3cbac989c47fa05e841b0841f09878e"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libjpeg-turbo*

# Explicitly link against libm, this is necessary on older glibc systems
atomic_patch -p1 $WORKSPACE/srcdir/patches/libjpeg-turbo-toplevel-libm.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/libjpeg-turbo-sharedlib-libm.patch

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
