# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libpng"
version = v"1.6.47"

# Collection of sources required to build libpng
sources = [
    ArchiveSource("https://sourceforge.net/projects/libpng/files/libpng16/$(version)/libpng-$(version).tar.gz",
                  "084115c62fe023e3d88cd78764a4d8e89763985ee4b4a085825f7a00d85eafbb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libpng-*
FLAGS=()
if [[ "${target}" == aarch64-apple-darwin* ]]; then
    # Let CMake know this platform supports NEON extension
    FLAGS+=(-DPNG_ARM_NEON=on)
fi
if [[ "${target}" == *-darwin* ]]; then
    # The framework is somehow confusing the linker
    # e.g. in GR (<https://github.com/JuliaPackaging/Yggdrasil/pull/8259>):
    #    error: cannot open /workspace/destdir/lib/png.framework: Is a directory
    #    error: linker command failed with exit code 1 (use -v to see invocation)
    FLAGS+=(-DPNG_FRAMEWORK=OFF)
fi
if [[ "${target}" == riscv64* ]]; then
    # Need to explicitly add `-lm`
    FLAGS+=(
        -DCMAKE_EXE_LINKER_FLAGS=-lm
        -DCMAKE_SHARED_LINKER_FLAGS=-lm
    )
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPNG_STATIC=OFF \
    "${FLAGS[@]}" \
    -B build
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpng16", :libpng)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
