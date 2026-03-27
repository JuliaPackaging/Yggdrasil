# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "microarchitectures.jl"))

name = "libaff3ct_jl"
version = v"0.1.0"

sources = [
    GitSource("https://github.com/zsoerenm/aff3ct.git",
              "5169fa0cb9b117c3aacf83bd950d075850aff1d8"),
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
    sed -i '/#include <execinfo.h>/d' lib/MIPP/src/mipp.h
    sed -i 's/defined(MIPP_ENABLE_BACKTRACE)/defined(MIPP_ENABLE_BACKTRACE) \&\& defined(__GLIBC__)/' lib/MIPP/src/mipp.h
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

# Create unversioned library symlink: macOS interprets dots in dylib names
# as version separators, so libaff3ct-4.2.0.dylib confuses BinaryBuilder's
# product check. An unversioned symlink avoids this on all platforms.
cd ${prefix}/lib
for f in libaff3ct-4.2.0.*; do
    ext="${f#libaff3ct-4.2.0}"
    ln -sf "$f" "libaff3ct${ext}"
done
cd ${WORKSPACE}/srcdir

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

products = [
    LibraryProduct("libaff3ct", :libaff3ct),
    LibraryProduct("libaff3ct_jl", :libaff3ct_jl),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8",
               julia_compat="1.6",
               augment_platform_block,
               dont_dlopen=true)
