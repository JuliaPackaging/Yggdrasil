using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "mlspp"
# Untagged: the commit Discord's libdave pins, 210 commits after v0.1.0
version = v"0.1.1"

sources = [
    GitSource("https://github.com/cisco/mlspp.git",
              "1cc50a124a3bc4e143a787ec934280dc70c1034d"),
]

# Configured like libdave's vcpkg port: libdave's sources use the `mlspp`
# namespace, and the port disables GREASE.
script = raw"""
cd ${WORKSPACE}/srcdir/mlspp
# OpenSSL_jll keeps the 64-bit MinGW import libraries in lib64
if [[ ${target} == x86_64-*-mingw* ]]; then
    export OPENSSL_ROOT_DIR=${prefix}/lib64
fi
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DMLS_CXX_NAMESPACE=mlspp \
    -DDISABLE_GREASE=ON \
    -DTESTING=OFF
cmake --build build --parallel ${nproc}
cmake --install build
# Upstream also installs its license as share/mlspp/copyright, which clashes
# with share/MLSPP (the CMake config) on case-insensitive file systems
rm -rv ${prefix}/share/mlspp
install_license LICENSE
"""

# std::variant's throwing accessors need libc++ from macOS 10.14
sources, script = require_macos_sdk("10.14", sources, script)

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct("libmlspp", :libmlspp),
    LibraryProduct("libhpke", :libhpke),
    LibraryProduct("libtls_syntax", :libtls_syntax),
    LibraryProduct("libbytes", :libbytes),
]

dependencies = [
    Dependency("OpenSSL_jll";
               compat="3.0.16"),
    BuildDependency("nlohmann_json_jll"),
    Dependency("CompilerSupportLibraries_jll";
               compat="1.1.2",
               platforms=filter(!Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6",
               preferred_gcc_version=v"8")
