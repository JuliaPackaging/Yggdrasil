# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch

const YGGDRASIL_DIR = "../.."
# For MicroArchitectures
include(joinpath(YGGDRASIL_DIR, "platforms", "microarchitectures.jl"))
# For should_build_platform
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
# For require_macos_sdk
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "fatrop"
version = v"1.2.0"

sources = [
    GitSource("https://github.com/meco-group/fatrop.git", "86929bad166f49109133a1bf7a5ae6ecb343b2a3"),   # v1.2.0
]

# Fatrop accesses the matrices of BLASFEO with `BLASFEO_DMATEL`, a macro of the headers of BLASFEO which
# depends on its panel size, so one variant is built per variant of blasfeo_jll.
#
# blasfeo_jll is built with BLASFEO's own Makefile, which installs into ${prefix}/blasfeo and ships no
# CMake package configuration, so the script writes one for `find_package(blasfeo)` to pick up.
script = raw"""
cd ${WORKSPACE}/srcdir/fatrop

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
    -DBUILD_WITH_C_INTERFACE=ON \
    -DBUILD_TESTS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -Dblasfeo_DIR=${WORKSPACE}/srcdir/blasfeo-cmake
cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE.txt LICENSE-EPL-2.0.txt
"""

# `std::visit` requires macOS 10.14
sources, script = require_macos_sdk("10.14", sources, script)

# The platforms of blasfeo_jll, whose variant is selected by the same microarchitecture augmentation
platforms = [
    expand_microarchitectures(filter(p -> Sys.islinux(p) && arch(p) == "x86_64", supported_platforms()), ["x86_64", "avx", "avx2", "avx512"]);
    expand_microarchitectures(filter(p -> Sys.iswindows(p) && arch(p) == "x86_64", supported_platforms()), ["x86_64", "avx", "avx2", "avx512"]);
    expand_microarchitectures(filter(p -> Sys.isapple(p) && arch(p) == "x86_64", supported_platforms()), ["x86_64", "avx", "avx2"]);
    expand_microarchitectures(filter(p -> Sys.isapple(p) && arch(p) == "aarch64", supported_platforms()), ["apple_m1"]);
]

products = [
    LibraryProduct(["libfatrop", "fatrop"], :libfatrop),
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
    Dependency("CompilerSupportLibraries_jll"; platforms = filter(!Sys.isapple, platforms)),
]

for platform in platforms
    should_build_platform(platform) || continue
    # Fatrop is written in C++17
    build_tarballs(ARGS, name, version, sources, script, [platform], products, dependencies;
                   julia_compat = "1.6", augment_platform_block, lock_microarchitecture = false,
                   preferred_gcc_version = v"10")
end
