using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "USDBrep"
version = v"1.0.0"

sources = [
    GitSource("https://github.com/NVIDIA-Omniverse/usd-brep.git",
              "c9c5979f04cea8c38213004d4f04df0dcfb40d05";
              tag="v$(version)"),
    DirectorySource("./bundled"),
]

# Upstream builds with premake and Packman-provided prebuilt dependencies; build with CMake instead
script = raw"""
apk del cmake
cd ${WORKSPACE}/srcdir/usd-brep
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmake.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw.patch
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -Dpxr_DIR=${prefix}
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE THIRD_PARTY_NOTICES.md
"""

# OpenUSD headers need std::shared_ptr<T[]>, missing from the default SDK's libc++
sources, script = require_macos_sdk("11.3", sources, script)

platforms = supported_platforms()
# OpenUSD_jll is only built for these
filter!(p -> arch(p) in ("x86_64", "aarch64"), platforms)
filter!(!Sys.isfreebsd, platforms)
filter!(p -> !(Sys.isapple(p) && arch(p) == "x86_64"), platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libSMLib", :libSMLib),
    LibraryProduct("libSM_API", :libSM_API),
    LibraryProduct("libBREP_USD_DATA", :libBREP_USD_DATA),
    LibraryProduct("libUSD_BREP_UTILS", :libUSD_BREP_UTILS),
    LibraryProduct("libBREP_SM_USD", :libBREP_SM_USD),
    LibraryProduct("libSM_API_USD", :libSM_API_USD),
    ExecutableProduct("occt_to_usd", :occt_to_usd),
    ExecutableProduct("occt_dump", :occt_dump),
    ExecutableProduct("usd_to_occt", :usd_to_occt),
    ExecutableProduct("smtess_usd", :smtess_usd),
    ExecutableProduct("brep_geometry_validator", :brep_geometry_validator),
    FileProduct("omniSolid/resources", :omnisolid_plugin_path),
]

dependencies = [
    HostBuildDependency("CMake_jll"),
    Dependency("OpenUSD_jll"; compat="25.11.0"),
    Dependency("oneTBB_jll"; compat="2022.0.0"),
]

# usd-brep finds its USD schema through OMNISOLID_PLUGIN_PATH
init_block = """
get!(ENV, "OMNISOLID_PLUGIN_PATH", omnisolid_plugin_path)
"""

# GCC 11's libstdc++ lacks the rvalue stream insertion (LWG 1203) used in BREP_SM_USD
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"12", init_block)
