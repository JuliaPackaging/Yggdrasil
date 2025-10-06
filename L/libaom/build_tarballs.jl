# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "libaom"
version = v"3.13.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://storage.googleapis.com/aom-releases/libaom-$(version).tar.gz",
                  "19e45a5a7192d690565229983dad900e76b513a02306c12053fb9a262cbeca7d"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/libaom-*

# Add missing stdint.h includes
# Reported upstream as <https://aomedia.issues.chromium.org/u/1/issues/432730317>
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/inttypes.patch

CMAKE_FLAGS=()
if [[ ${target} = arm-* ]]; then
    # Not even GCC 13 can compile for 32-bit ARM
    CMAKE_FLAGS+=(-DAOM_TARGET_CPU=generic)
elif [[ ${target} = aarch64-*-freebsd* ]]; then
    # Runtime CPU detection doesn't work
    CMAKE_FLAGS+=(-DCONFIG_RUNTIME_CPU_DETECT=0)
fi

cmake -B build-dir -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DENABLE_TESTS=OFF \
    ${CMAKE_FLAGS[@]}
cmake --build build-dir --parallel ${nproc}
cmake --install build-dir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("aomenc", :aomenc),
    ExecutableProduct("aomdec", :aomdec),
    LibraryProduct(["libaom", "aom"], :libaom),
]

# Dependencies that must be installed before this package can be built
#
# YASM is recommended in the build instructions, but errors on apple platforms.
# Assembly only exists for x86 targets.
dependencies = [
    HostBuildDependency("YASM_jll"; platforms=filter(p->proc_family(p) == "intel" && !Sys.isapple(p), platforms)),
    HostBuildDependency("NASM_jll"; platforms=filter(p->proc_family(p) == "intel" && Sys.isapple(p), platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 9 for proper support of Intel SIMD intrinsics
# We need at least GCC 10 for proper support of 64-bit ARM SIMD intrinsics
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", lock_microarchitecture=false, preferred_gcc_version=v"10")
