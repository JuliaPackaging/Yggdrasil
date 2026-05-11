# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "microarchitectures.jl"))

name = "aff3ct"
version = v"4.2.0"

sources = [
    GitSource("https://github.com/aff3ct/aff3ct.git",
              "bd436ca2d8176983668d3dfbe231d6b52d9b5d06"),
    GitSource("https://github.com/JuliaGNSS/libaff3ct_jl.git",
              "2d7645a4cae0ffd446bf51d0aef2bcbcac13a605"),
]

script = raw"""
# ── Build aff3ct ──────────────────────────────────────────────
cd ${WORKSPACE}/srcdir/aff3ct*

# Rewrite relative submodule URLs to absolute GitHub URLs so they resolve in the sandbox
sed -i 's|url = \.\./MIPP|url = https://github.com/aff3ct/MIPP.git|' .gitmodules
sed -i 's|url = \.\./configuration_files|url = https://github.com/aff3ct/configuration_files.git|' .gitmodules
sed -i 's|url = \.\./error_rate_references|url = https://github.com/aff3ct/error_rate_references.git|' .gitmodules
sed -i 's|url = \.\./cli|url = https://github.com/aff3ct/cli.git|' .gitmodules
sed -i 's|url = \.\./streampu|url = https://github.com/aff3ct/streampu.git|' .gitmodules
git submodule sync
git submodule update --init --recursive --depth 1

# musl doesn't have <execinfo.h> (glibc extension for backtrace).
# Patch streampu and MIPP to guard their includes with __GLIBC__.
if [[ "${target}" == *-musl* ]]; then
    sed -i 's/#include <execinfo.h>//' lib/streampu/src/Tools/system_functions.cpp
    sed -i '/#include <execinfo.h>/d' lib/MIPP/include/mipp.h
    sed -i 's/defined(MIPP_ENABLE_BACKTRACE)/defined(MIPP_ENABLE_BACKTRACE) \&\& defined(__GLIBC__)/' lib/MIPP/include/mipp.h
fi

mkdir build && cd build

# Map BinaryBuilder march tag to SIMD compiler flags for MIPP
SIMD_FLAGS=""
if [[ "${march}" == "avx" ]]; then
    SIMD_FLAGS="-mavx"
elif [[ "${march}" == "avx2" ]]; then
    SIMD_FLAGS="-mavx2 -mfma"
elif [[ "${march}" == "avx512" ]]; then
    SIMD_FLAGS="-mavx512f -mavx512bw"
fi

cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DAFF3CT_COMPILE_EXE=OFF \
    -DAFF3CT_COMPILE_SHARED_LIB=ON \
    -DSPU_STACKTRACE=OFF \
    -DAFF3CT_OVERRIDE_VERSION="v4.2.0" \
    -DCMAKE_CXX_FLAGS="${SIMD_FLAGS}"

make -j${nproc}
make install

# ── Build libaff3ct_jl ────────────────────────────────────────
cd ${WORKSPACE}/srcdir/libaff3ct_jl*
rm -rf build && mkdir build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${prefix}" \
    -DBUILD_TESTING=OFF
make -j${nproc}
make install

# Install license
install_license ${WORKSPACE}/srcdir/libaff3ct_jl*/LICENSE
"""

# Filter out Windows (aff3ct/streampu has compilation issues on MinGW), then
# expand for x86_64 microarchitectures (MIPP selects SIMD at compile time).
platforms = expand_cxxstring_abis(
    expand_microarchitectures(supported_platforms(; exclude=Sys.iswindows), ["x86_64", "avx", "avx2", "avx512"])
)

augment_platform_block = """
    $(MicroArchitectures.augment)

    function augment_platform!(platform::Platform)
        @static if Sys.ARCH === :x86_64
            augment_microarchitecture!(platform)
        else
            platform
        end
    end
    """

# The microarchitecture variants bake SIMD instructions into static
# initializers, so dlopen'ing them on an incompatible build host raises
# SIGILL. augment_platform_block ensures users only download a variant
# matching their CPU, so skip the audit's dlopen check.
products = [
    # libaff3ct-4.2.0 is the CMake install name on Linux; macOS strips
    # the trailing .2.0 as a dylib version suffix, leaving "libaff3ct-4".
    LibraryProduct(["libaff3ct-4.2.0", "libaff3ct-4"], :libaff3ct; dont_dlopen=true),
    LibraryProduct("libaff3ct_jl", :libaff3ct_jl; dont_dlopen=true),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8",
               julia_compat="1.6",
               augment_platform_block)
