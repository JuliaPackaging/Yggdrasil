# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "OpenEXR"
version = v"3.4.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AcademySoftwareFoundation/openexr.git", "741ecb82ccdb291ce5b04713fc6c03208753575e"),
    DirectorySource("bundled"),
]


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openexr*
cmake -B build -G Ninja \
    -DBUILD_TESTING=OFF \
    -DOPENEXR_INSTALL_TOOLS=OFF \
    -DOPENEXR_INSTALL_EXAMPLES=OFF \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
# We are building with old kernel headers that do not define `HWCAP_SVE2`
atomic_patch -p1 $WORKSPACE/srcdir/patches/sve2.patch
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
    LibraryProduct("libOpenEXRUtil-3_4", :libOpenEXRUtil),
    LibraryProduct("libOpenEXRCore-3_4", :libOpenEXRCore),
    LibraryProduct("libOpenEXR-3_4", :libOpenEXR),
    LibraryProduct("libIlmThread-3_4", :libIlmThread),
    LibraryProduct("libIex-3_4", :libIex),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Minor releases of `Imath_jll` are breaking, patch releases are not
    Dependency("Imath_jll"; compat="~3.2.2"),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 6 on aarch64 to support assembler intrinsics there
# We need at least GCC 9 for `std::filesystem`
# We need at least GCC 10 to avoid a GCC `.seh_savexmm` bug on mingw
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
