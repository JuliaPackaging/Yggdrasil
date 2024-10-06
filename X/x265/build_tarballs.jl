# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "x265"
version = v"4.0"

# NOTE: The release notes for version 4.0 do not mention any
# incompatibility with version 3.6. Packages currently using 3.6 might
# try building against 4.0.

# Collection of sources required to build x265
sources = [
    GitSource("https://bitbucket.org/multicoreware/x265_git.git",
              "4ecee600df03bc5c7679d2caf702be9169f41aec"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/*x265*/
# Remove `-march` and `-mcpu` flags
SED_SCRIPTS=(-e  -e -- 's/-mcpu=native //g')
for CMAKE_FILE in source/CMakeLists.txt source/dynamicHDR10/CMakeLists.txt; do
    sed -i 's/add_definitions(-march=i686)//g' "${CMAKE_FILE}"
    sed -i 's/-mcpu=native //g' "${CMAKE_FILE}"
done
FLAGS=()
cmake -S source -B build \
    -DCMAKE_INSTALL_PREFIX="${prefix}" \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DENABLE_PIC=ON \
    -DENABLE_SHARED=ON \
    ${FLAGS[@]}
cmake --build build --parallel ${nproc}
cmake --install build
# Remove the large static archive
rm -v ${prefix}/lib/libx265.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("x265", :x265),
    LibraryProduct("libx265", :libx265)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We need `nasm` for x86_64
    HostBuildDependency("NASM_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need GCC 10 to support the aarch64 assembler intrinsics.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
