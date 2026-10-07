# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "OpenEXR"
version = v"3.5.2"
# Note: Different minor versions of `OpenEXR_jll` are not ABI compatible.
# All downstream packages know this and use explicit compat bounds.

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AcademySoftwareFoundation/openexr.git", "69b2604fc76e370615438bdc8d2cd95b9349c12e"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openexr*

#TODO # We are building with old kernel headers that do not define `HWCAP_SVE2`
#TODO atomic_patch -p1 $WORKSPACE/srcdir/patches/sve2.patch
#TODO # We are building with an old glibc that does not define `AT_HWCAP2`
#TODO atomic_patch -p1 $WORKSPACE/srcdir/patches/hwcap2.patch

cmake_options=(
    -DBUILD_TESTING=OFF
    -DOPENEXR_BUILD_TOOLS=OFF
    -DOPENEXR_BUILD_EXAMPLES=OFF
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
)

# Disable run-time CPU detection on x86_64-apple
# (avoid `ld64.lld: error: undefined symbol: __cpu_model`)
if [[ "${target}" == x86_64-apple-* ]]; then
    cmake_options+=(
        -DOPENEXR_ENABLE_X86_SIMD=OFF
    )
fi

cmake -Bbuild -GNinja "${cmake_options[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE.md
install_license PATENTS
"""

# We need macos 10.14 for `std::any_cast`
# We need macos 10.15 for `aligned_alloc`
sources, script = require_macos_sdk("11.0", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libOpenEXRUtil-3_5", :libOpenEXRUtil),
    LibraryProduct("libOpenEXRCore-3_5", :libOpenEXRCore),
    LibraryProduct("libOpenEXR-3_5", :libOpenEXR),
    LibraryProduct("libIlmThread-3_5", :libIlmThread),
    LibraryProduct("libIex-3_5", :libIex),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Minor releases of `Imath_jll` are breaking, patch releases are not
    Dependency("Imath_jll"; compat="~3.2.2"),
    Dependency("OpenJPH_jll"; compat="0.32.0"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"; compat="1.5.7"),
    Dependency("libdeflate_jll"; compat="1.26"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 6 on aarch64 to support assembler intrinsics there
# We need at least GCC 9 for `std::filesystem`
# We need at least GCC 10 to avoid a GCC `.seh_savexmm` bug on mingw
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
