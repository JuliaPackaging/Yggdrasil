# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "x265"
version = v"3.5"

# Collection of sources required to build x265
sources = [
    # Note: x265 is only available as a Mercurial repository at
    # http://hg.videolan.org/x265/ They aren't publishing release tarballs
    # anymore.  This source is a git mirror on BitBucket.
    ArchiveSource("https://bitbucket.org/multicoreware/x265_git/get/Release_$(version.major).$(version.minor).tar.bz2",
                  "8692745fc050930e16dff725895c9201b3a9812467f570ada2f156f44b153c71"),
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
mkdir bld && cd bld
FLAGS=()
if [[ "${target}" == i686-* ]] || [[ "${target}" == aarch64-apple-darwin* ]]; then
    FLAGS+=(-DENABLE_ASSEMBLY=OFF)
fi
cmake -DCMAKE_INSTALL_PREFIX="${prefix}" \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DENABLE_PIC=ON \
    -DENABLE_SHARED=ON \
    ${FLAGS[@]} \
    ../source
make -j${nproc}
make install
# Remove the large static archive
rm  ${prefix}/lib/libx265.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
