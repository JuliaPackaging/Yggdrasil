# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch

const YGGDRASIL_DIR = "../.."
# For MicroArchitectures
include(joinpath(YGGDRASIL_DIR, "platforms", "microarchitectures.jl"))
# For should_build_platform
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "acados"
version = v"0.6.0"

# acados (https://github.com/acados/acados) built against blasfeo_jll and hpipm_jll instead of the
# copies it carries as submodules. Only the HPIPM QP solver is built; the optional third-party QP
# solvers (qpOASES, DAQP, OSQP, qpDUNES, HPMPC, Clarabel) are left out. Besides the library and the
# headers, the artifact carries acados' Tera C templates (`share/acados/c_templates_tera`), which
# together with `tera_renderer_jll` render standalone C solvers without the Python `acados_template`
# package.
sources = [
    GitSource("https://github.com/acados/acados.git", "503364817c872d474ab5bed219c26760ac267769"),   # v0.6.0
    DirectorySource("./bundled"),
]

# acados can be pointed at an installed BLASFEO with `ACADOS_WITH_SYSTEM_BLASFEO`, but it always
# compiles the HPIPM submodule, so one patch adds the matching `ACADOS_WITH_SYSTEM_HPIPM` option. A few
# includes spell the BLASFEO headers relative to the submodule directory instead of flat as the rest of
# the sources do, which only resolves for the bundled copy; the other patch makes them flat as well.
#
# blasfeo_jll is built with BLASFEO's own Makefile, which installs into ${prefix}/blasfeo and ships no
# CMake package configuration, so the script writes one for `find_package(blasfeo)`. hpipm_jll ships
# the configuration CMake exported for it.
script = raw"""
cd ${WORKSPACE}/srcdir/acados
for p in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${p}
done

# MinGW's header is windows.h (case-sensitive file systems)
sed -i 's/<Windows.h>/<windows.h>/' acados/utils/timing.h

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
    -DACADOS_INSTALL_DIR=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DACADOS_WITH_SYSTEM_BLASFEO=ON \
    -Dblasfeo_DIR=${WORKSPACE}/srcdir/blasfeo-cmake \
    -DACADOS_WITH_SYSTEM_HPIPM=ON \
    -Dhpipm_DIR=${prefix}/cmake \
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

install_license LICENSE
"""

# BLASFEO selects its kernels at compile time and its target determines the panel size the acados
# structures are laid out with, so one variant is built per microarchitecture, matching the variants
# blasfeo_jll and hpipm_jll provide.
platforms = [
    expand_microarchitectures(filter(p -> Sys.islinux(p) && arch(p) == "x86_64", supported_platforms()), ["x86_64", "avx", "avx2", "avx512"]);
    expand_microarchitectures(filter(p -> Sys.iswindows(p) && arch(p) == "x86_64", supported_platforms()), ["x86_64", "avx", "avx2", "avx512"]);
    expand_microarchitectures(filter(p -> Sys.isapple(p) && arch(p) == "x86_64", supported_platforms()), ["x86_64", "avx", "avx2"]);
    expand_microarchitectures(filter(p -> Sys.isapple(p) && arch(p) == "aarch64", supported_platforms()), ["apple_m1"]);
]

# On Windows the CMake build drops the `lib` prefix (acados.dll)
products = [
    LibraryProduct(["libacados", "acados"], :libacados),
    FileProduct("share/acados/c_templates_tera/acados_solver.in.c", :acados_solver_template),   # dirname(...) is the templates dir
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
    Dependency("hpipm_jll"; compat = "0.1.4"),
]

for platform in platforms
    should_build_platform(platform) || continue
    # mingw-gcc before v10 fails to assemble the AVX-512 code ("invalid register for .seh_savexmm"),
    # see https://gcc.gnu.org/bugzilla/show_bug.cgi?id=65782. As in B/blasfeo, v"10" is the value
    # `preferred_gcc_version` needs to select a compiler without the bug.
    gcc_version = Sys.iswindows(platform) && platform["march"] == "avx512" ? v"10" : nothing
    build_tarballs(ARGS, name, version, sources, script, [platform], products, dependencies;
                   julia_compat = "1.6", augment_platform_block, preferred_gcc_version = gcc_version)
end
