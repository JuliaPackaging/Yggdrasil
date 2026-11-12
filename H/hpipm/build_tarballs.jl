# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch

const YGGDRASIL_DIR = "../.."
# For MicroArchitectures
include(joinpath(YGGDRASIL_DIR, "platforms", "microarchitectures.jl"))
# For should_build_platform
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "hpipm"
version = v"0.1.4"

sources = [
    GitSource("https://github.com/giaf/hpipm.git", "d4b267ba322aed8343a446d552cf048a2f8cf624"),   # v0.1.4
]

# HPIPM selects its kernels at compile time, so one variant is built per microarchitecture, following
# the variants blasfeo_jll provides: the AVX target where the microarchitecture has AVX, GENERIC
# elsewhere. The AVX target only replaces the interior-point core auxiliary routines, which operate on
# plain vectors, so it is independent of the panel size of the BLASFEO variant it is linked against.
#
# blasfeo_jll is built with BLASFEO's own Makefile, which installs into ${prefix}/blasfeo and ships no
# CMake package configuration, so the script writes one for HPIPM_FIND_BLASFEO to pick up.
function get_script(; platform::Platform)
    target = arch(platform) == "x86_64" && platform["march"] in ("avx", "avx2", "avx512") ? "AVX" : "GENERIC"
    return "HPIPM_TARGET=$(target)\n" * raw"""
cd ${WORKSPACE}/srcdir/hpipm

mkdir -p ${WORKSPACE}/srcdir/blasfeo-cmake
cat > ${WORKSPACE}/srcdir/blasfeo-cmake/blasfeoConfig.cmake <<EOF
add_library(blasfeo SHARED IMPORTED GLOBAL)
set_target_properties(blasfeo PROPERTIES
    IMPORTED_LOCATION "${prefix}/blasfeo/lib/libblasfeo.${dlext}"
    IMPORTED_IMPLIB "${prefix}/blasfeo/lib/libblasfeo.${dlext}"
    INTERFACE_INCLUDE_DIRECTORIES "${prefix}/blasfeo/include")
EOF

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DTARGET=${HPIPM_TARGET} \
    -DHPIPM_FIND_BLASFEO=ON \
    -Dblasfeo_DIR=${WORKSPACE}/srcdir/blasfeo-cmake \
    -DBLASFEO_PATH=${prefix}/blasfeo \
    -DHPIPM_TESTING=OFF \
    -DHPIPM_HEADERS_INSTALLATION_DIRECTORY=include/hpipm/include
cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE.txt
"""
end

# The platforms of blasfeo_jll, whose variant is selected by the same microarchitecture augmentation
platforms = [
    expand_microarchitectures(filter(p -> Sys.islinux(p) && arch(p) == "x86_64", supported_platforms()), ["x86_64", "avx", "avx2", "avx512"]);
    expand_microarchitectures(filter(p -> Sys.iswindows(p) && arch(p) == "x86_64", supported_platforms()), ["x86_64", "avx", "avx2", "avx512"]);
    expand_microarchitectures(filter(p -> Sys.isapple(p) && arch(p) == "x86_64", supported_platforms()), ["x86_64", "avx", "avx2"]);
    expand_microarchitectures(filter(p -> Sys.isapple(p) && arch(p) == "aarch64", supported_platforms()), ["apple_m1"]);
]

# On Windows the CMake build drops the `lib` prefix (hpipm.dll)
products = [
    LibraryProduct(["libhpipm", "hpipm"], :libhpipm),
]

# augment_platform so the microarchitecture variant matching the host is selected
augment_platform_block = """
$(MicroArchitectures.augment)

function augment_platform!(platform::Platform)
    augment_microarchitecture!(platform)
end
"""

dependencies = [
    Dependency("blasfeo_jll"; compat = "0.1.4"),
]

for platform in platforms
    should_build_platform(platform) || continue
    build_tarballs(ARGS, name, version, sources, get_script(; platform), [platform], products, dependencies;
                   julia_compat = "1.6", augment_platform_block, lock_microarchitecture = false)
end
