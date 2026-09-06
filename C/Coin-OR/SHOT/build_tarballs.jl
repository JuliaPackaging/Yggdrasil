const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

include("../coin-or-common.jl")

sources = [
    GitSource(
        "https://github.com/coin-or/SHOT.git",
        SHOT_gitsha,
    ),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/SHOT
git submodule update --init --recursive
# Disable run_source_test in CppAD
atomic_patch -p1 ../patches/CppAD.patch
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L${libdir}"
fi

mkdir -p build
cd build

cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHAS_CBC=on \
    -DCBC_DIR=${prefix} \
    -DHAS_IPOPT=on \
    -DIPOPT_DIR=${prefix} \
    -DHAS_AMPL=on \
    -DGENERATE_EXE=on \
    ..

make -j${nproc}
make install

install_license ../LICENSE
"""

# Work around the issue
#     /workspace/srcdir/SHOT/src/Model/../Model/Simplifications.h:1370:26: error: 'value' is unavailable: introduced in macOS 10.14
#                     optional.value()->coefficient *= -1.0;
#                              ^
#     /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/include/c++/v1/optional:947:27: note: 'value' has been explicitly marked unavailable here
#         constexpr value_type& value() &
#                               ^
# ...and install a newer SDK which supports `std::filesystem`
sources, script = require_macos_sdk("10.15", sources, script)

products = [
    ExecutableProduct("SHOT", :amplexe),
    LibraryProduct("libSHOTSolver", :libshotsolver),
]

dependencies = [
    Dependency("ASL_jll", ASL_version),
    Dependency("Cbc_jll", compat="$(Cbc_version)"),
    Dependency("Ipopt_jll", compat="$(Ipopt_version)"),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(
    ARGS,
    "SHOT",
    SHOT_version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
    preferred_gcc_version = v"9",
)
