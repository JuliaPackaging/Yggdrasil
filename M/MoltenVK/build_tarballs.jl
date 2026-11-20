using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "MoltenVK"
version = v"1.4.1"

# MoltenVK links its dependencies statically, at the exact revisions listed in its
# ExternalRevisions directory, and SPIRV-Cross under a private namespace, so they can't
# come from JLLs.
sources = [
    GitSource("https://github.com/KhronosGroup/MoltenVK.git",
              "db445ff2042d9ce348c439ad8451112f354b8d2a"; tag="v$(version)"),
    GitSource("https://github.com/KhronosGroup/SPIRV-Cross.git",
              "adec7acbf41a988713cdb85f93f26c8ca5ea863e"),
    GitSource("https://github.com/KhronosGroup/SPIRV-Headers.git",
              "b824a462d4256d720bebb40e78b9eb8f78bbb305"),
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git",
              "262bdab48146c937467f826699a40da0fdfc0f1a"),
    GitSource("https://github.com/KhronosGroup/Vulkan-Headers.git",
              "6aefb8eb95c8e170d0805fd0f2d02832ec1e099a"),
    GitSource("https://github.com/USCiLab/cereal.git",
              "a56bad8bbb770ee266e930c95d37fff2a5be7fea"),
    FileSource("https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.8/CPM.cmake",
               "78ba32abdf798bc616bab7c73aac32a17bbd7b06ad9e26a6add69de8f3ae4791"),
    DirectorySource("./bundled"),
]

script = raw"""
# Use the newer CMake from CMake_jll
apk del cmake

cd ${WORKSPACE}/srcdir/MoltenVK
atomic_patch -p1 ../patches/relative-icd-library-path.patch

# MoltenVK's CMake downloads CPM and, through it, the dependencies; give it the sources above
install -Dvm 644 ../CPM.cmake ../cpm-cache/cpm/CPM_0.40.8.cmake

deps=(SPIRV-Cross SPIRV-Headers SPIRV-Tools Vulkan-Headers cereal)
CMAKE_FLAGS=(-DCPM_SOURCE_CACHE=${WORKSPACE}/srcdir/cpm-cache)
for dep in ${deps[@]}; do
    CMAKE_FLAGS+=(-DCPM_${dep}_SOURCE=${WORKSPACE}/srcdir/${dep})
done

cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ${CMAKE_FLAGS[@]}
ninja -C build -j${nproc} install

install_license LICENSE
for dep in ${deps[@]}; do
    mkdir -pv ${prefix}/share/licenses/${SRC_NAME}/${dep}
    cp -rv ../${dep}/LICENSE* ${prefix}/share/licenses/${SRC_NAME}/${dep}/
done
"""

# MoltenVK features depend on the SDK it is built with (MVK_XCODE_* macros), so use the newest
# one available. The deployment target is the oldest macOS that MoltenVK 1.4.1 supports.
sources, script = require_macos_sdk("15.0", sources, script; deployment_target="11.0")

# MoltenVK implements Vulkan on top of Apple's Metal
platforms = filter!(Sys.isapple, supported_platforms())

products = [
    LibraryProduct("libMoltenVK", :libMoltenVK),
    FileProduct("etc/vulkan/icd.d/MoltenVK_icd.json", :MoltenVK_icd),
]

dependencies = [
    # SPIRV-Tools needs CMake 3.22.1
    HostBuildDependency(PackageSpec(; name="CMake_jll", version="3.22.2")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
