# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "Kiwi"
version = v"0.25.0"
# Raising julia_compat needed a new JLL version after Kiwi_jll v0.25.0 was built.
# Drop ygg_version once upstream releases a version above 0.25.1.
ygg_version = v"0.25.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bab2min/Kiwi.git",
              "6ffacb7c59da6fabf3cc7a6e6ee3652126fc6004"; tag="v$(version)"),
    # Header-only B-tree fork vendored by Kiwi as a git submodule; no JLL exists.
    GitSource("https://github.com/bab2min/cpp-btree.git",
              "226ce3aed24702bef1b03dba4b3cb55bc0bf31dd"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Kiwi
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/kiwi-build-static-option.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/kiwi-system-deps.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/kiwi-mingw-windows-h.patch
rm -rvf third_party/cpp-btree
cp -rv ../cpp-btree third_party/cpp-btree

# neon.cpp forces -march=armv8-a, the AArch64 baseline
sed -i 's/-march=armv8-a//' CMakeLists.txt

cmake_args=()
if [[ "${nbits}" == 32 ]]; then
    # Kiwi's SIMD kernels are for x86_64 and AArch64 only, but on 32-bit targets upstream still
    # selects them: CMake's `^(arm|aarch64)` match and cpuinfo's CPUINFO_ARCH_ARM enable the
    # AArch64-only NEON code on armv6l/armv7l, and the cpuinfo-based dispatch lists the sse2
    # kernel, which is not built, on i686. Use the portable code there instead.
    cmake_args+=(-DKIWI_CPU_ARCH=other -DKIWI_USE_CPUINFO=OFF)
fi
jobs=${nproc}
if [[ "${target}" == *-mingw32 ]]; then
    # Equivalent of MSVC /bigobj, which upstream uses: the templated SIMD kernels exceed the
    # default COFF section count. Their long section names also need binutils >= 2.41, which
    # encodes string table offsets above 9999999 in base64 ("string table overflow" otherwise).
    export CXXFLAGS="-Wa,-mbig-obj"
fi
if [[ "${target}" == x86_64-w64-mingw32 ]]; then
    # Compiling CoNgramModel.cpp, Knlm.cpp and SkipBigramModel.cpp here takes up to 9.5, 5.3
    # and 3.0 GB; with ${nproc} jobs CI killed cc1plus for lack of memory.
    jobs=1
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DKIWI_USE_SYSTEM_DEPS=ON \
    -DKIWI_BUILD_STATIC=OFF \
    -DKIWI_BUILD_CLI=OFF \
    -DKIWI_BUILD_EVALUATOR=OFF \
    -DKIWI_BUILD_MODEL_BUILDER=OFF \
    -DKIWI_BUILD_TEST=OFF \
    "${cmake_args[@]}"
cmake --build build --parallel ${jobs}
cmake --install build

install_license LICENSE NOTICE
# Compiled into libkiwi: cpp-btree from source, Eigen and nlohmann_json from their headers
install -Dvm 644 ../cpp-btree/LICENSE ${prefix}/share/licenses/${SRC_NAME}/LICENSE.cpp-btree
install_license ${prefix}/share/licenses/Eigen/COPYING.MPL2
install_license ${prefix}/share/licenses/nlohmann_json/LICENSE.MIT
"""

# std::visit and aligned allocation need macOS 10.14
sources, script = require_macos_sdk("10.14", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()
# CPUInfo_jll is not built for these
filter!(p -> arch(p) != "powerpc64le", platforms)
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libkiwi", :libkiwi),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Kiwi pins Eigen 3.4.0
    BuildDependency(PackageSpec(; name="Eigen_jll", version="3.4.0")),
    BuildDependency(PackageSpec(; name="nlohmann_json_jll", version="3.12.0")),
    # libgcc_s and libstdc++; admits the 1.0.5 that Julia 1.10 ships
    Dependency(PackageSpec(; name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               compat="1.0.2"),
    Dependency("StreamVByte_jll"; compat="2.0.0"),
    Dependency("CPUInfo_jll"; compat="0.0.20260415"),
    Dependency("mimalloc_jll"; compat="3.5.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 11: Kiwi builds its AVX-VNNI kernel only with GCC >= 11.
# Windows needs GCC 13 for its binutils 2.41 (see the comment in the script above).
# julia_compat 1.10: Julia 1.9.4's libopenlibm needs an executable stack, which current glibc
# refuses, so Julia 1.9 no longer starts on General's AutoMerge runners. Julia 1.10's
# libstdc++ covers what the GCC 11 (Linux) and GCC 13 (Windows) builds of libkiwi import.
for platform in platforms
    should_build_platform(triplet(platform)) || continue
    preferred_gcc_version = if Sys.iswindows(platform)
        v"13"
    else
        v"11"
    end
    build_tarballs(ARGS, name, ygg_version, sources, script, [platform], products, dependencies;
                   julia_compat="1.10", preferred_gcc_version)
end
