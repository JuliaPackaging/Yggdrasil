# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

const YGGDRASIL_DIR = "../.."
# For MicroArchitectures
include(joinpath(YGGDRASIL_DIR, "platforms", "microarchitectures.jl"))
# For should_build_platform
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "acados"
version = v"0.6.0"

# acados (https://github.com/acados/acados) with the BLASFEO and HPIPM versions it pins as
# submodules (the sandbox cannot fetch submodules, so they are separate sources moved into place).
# Only the HPIPM QP solver is built; the optional third-party QP solvers (qpOASES, DAQP, OSQP,
# qpDUNES, HPMPC, Clarabel) are left out. Besides the libraries and headers, the artifact carries
# acados' Tera C templates (`share/acados/c_templates_tera`), which together with `tera_renderer_jll`
# render standalone C solvers without the Python `acados_template` package.
sources = [
    GitSource("https://github.com/acados/acados.git", "503364817c872d474ab5bed219c26760ac267769"),   # v0.6.0
    GitSource("https://github.com/giaf/blasfeo.git", "d6251233923c9b475fe894fb729fb63ab693e301"),   # external/blasfeo at v0.6.0
    GitSource("https://github.com/giaf/hpipm.git", "e3a56c1caddd7f12d125d84f337b9a9e5c186271"),     # external/hpipm at v0.6.0
]

# BLASFEO's kernels are selected at compile time by TARGET (no runtime dispatch), so the recipe
# builds one variant per microarchitecture tag, as B/blasfeo does (the tag must match the host's
# exactly, so every x86_64 tag is built): GENERIC C code as the fallback, X64_INTEL_SANDY_BRIDGE for
# avx, X64_INTEL_HASWELL for avx2 and avx512 (BLASFEO's AVX-512 targets are tuned for specific chips),
# and ARMV8A_APPLE_M1 on Apple silicon. HPIPM has AVX and GENERIC variants.
function get_script(; platform::Platform)
    if arch(platform) == "x86_64" && haskey(platform, "march")
        blasfeo_target, hpipm_target = if platform["march"] == "avx"
            # BLASFEO's Sandy Bridge target misses single-precision kernels under MinGW (undefined
            # kernel_sgemm_nt_16x4_lib8), so Windows gets the generic kernels there
            Sys.iswindows(platform) ? "GENERIC" : "X64_INTEL_SANDY_BRIDGE", "AVX"
        elseif platform["march"] in ("avx2", "avx512")
            "X64_INTEL_HASWELL", "AVX"
        else
            "GENERIC", "GENERIC"
        end
    elseif arch(platform) == "aarch64" && os(platform) == "macos" && haskey(platform, "march") && platform["march"] == "apple_m1"
        blasfeo_target, hpipm_target = "ARMV8A_APPLE_M1", "GENERIC"
    else
        blasfeo_target, hpipm_target = "GENERIC", "GENERIC"
    end
    return "BLASFEO_TARGET=$(blasfeo_target)\nHPIPM_TARGET=$(hpipm_target)\n" * raw"""
cd ${WORKSPACE}/srcdir/acados
rm -rf external/blasfeo external/hpipm
mv ../blasfeo external/blasfeo
mv ../hpipm external/hpipm

# MinGW's header is windows.h (case-sensitive file systems)
sed -i 's/<Windows.h>/<windows.h>/' acados/utils/timing.h

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DACADOS_INSTALL_DIR=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBLASFEO_TARGET=${BLASFEO_TARGET} \
    -DHPIPM_TARGET=${HPIPM_TARGET} \
    -DLA=HIGH_PERFORMANCE \
    -DACADOS_WITH_QPOASES=OFF \
    -DACADOS_WITH_DAQP=OFF \
    -DACADOS_WITH_OSQP=OFF \
    -DACADOS_WITH_QPDUNES=OFF \
    -DACADOS_WITH_HPMPC=OFF \
    -DACADOS_WITH_CLARABEL=OFF \
    -DACADOS_WITH_OPENMP=OFF \
    -DACADOS_EXAMPLES=OFF \
    -DACADOS_UNIT_TESTS=OFF \
    -DACADOS_SILENT=ON
cmake --build build --parallel ${nproc}
cmake --install build

# The C templates acados_template renders solvers from (used with tera_renderer_jll)
mkdir -p ${prefix}/share/acados
cp -r interfaces/acados_template/acados_template/c_templates_tera ${prefix}/share/acados/

cp external/blasfeo/LICENSE.txt LICENSE-blasfeo.txt
cp external/hpipm/LICENSE.txt LICENSE-hpipm.txt
install_license LICENSE LICENSE-blasfeo.txt LICENSE-hpipm.txt
"""
end

platforms = [
    expand_microarchitectures(filter(p -> Sys.islinux(p) && arch(p) == "x86_64", supported_platforms()), ["x86_64", "avx", "avx2", "avx512"]);
    expand_microarchitectures(filter(p -> Sys.iswindows(p) && arch(p) == "x86_64", supported_platforms()), ["x86_64", "avx", "avx2", "avx512"]);
    expand_microarchitectures(filter(p -> Sys.isapple(p) && arch(p) == "x86_64", supported_platforms()), ["x86_64", "avx", "avx2", "avx512"]);
    expand_microarchitectures(filter(p -> Sys.isapple(p) && arch(p) == "aarch64", supported_platforms()), ["apple_m1"]);
    filter(p -> Sys.islinux(p) && arch(p) == "aarch64", supported_platforms());
    filter(p -> Sys.isfreebsd(p) && arch(p) == "x86_64", supported_platforms());
]

# On Windows the CMake builds drop the `lib` prefix (acados.dll, hpipm.dll, blasfeo.dll)
products = [
    LibraryProduct(["libacados", "acados"], :libacados),
    LibraryProduct(["libhpipm", "hpipm"], :libhpipm),
    LibraryProduct(["libblasfeo", "blasfeo"], :libblasfeo),
    FileProduct("share/acados/c_templates_tera/acados_solver.in.c", :acados_solver_template),   # dirname(...) is the templates dir
]

# augment_platform so the fastest matching microarchitecture variant is selected
augment_platform_block = """
$(MicroArchitectures.augment)

function augment_platform!(platform::Platform)
    augment_microarchitecture!(platform)
end
"""

dependencies = Dependency[]

for platform in platforms
    should_build_platform(platform) || continue
    build_tarballs(ARGS, name, version, sources, get_script(; platform), [platform], products, dependencies;
                   julia_compat = "1.6", augment_platform_block, lock_microarchitecture = false)
end
