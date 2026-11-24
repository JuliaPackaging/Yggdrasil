using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "MoltenVK"
version = v"1.4.2"

# CPM_DOWNLOAD_VERSION in MoltenVK's cmake/recipes/CPM.cmake
cpm_version = v"0.40.8"

# MoltenVK links its dependencies statically, at the exact revisions listed in its
# ExternalRevisions directory, and SPIRV-Cross under a private namespace, so they can't
# come from JLLs.
#
# When updating MoltenVK, take the dependency commits from its ExternalRevisions/*_repo_revision
# files, and `cpm_version` from CPM_DOWNLOAD_VERSION in its cmake/recipes/CPM.cmake.
sources = [
    GitSource("https://github.com/KhronosGroup/MoltenVK.git",
              "db66022459ffb663aa2b50f6b018bc2e124f5edf"; tag="v$(version)"),
    GitSource("https://github.com/KhronosGroup/SPIRV-Cross.git",
              "6c09849fe88c48eaed08413aa022aaa136a3a057"),
    GitSource("https://github.com/KhronosGroup/SPIRV-Headers.git",
              "29981f65241605e08b0ede4cfeb999fe3b723c6a"),
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git",
              "0d6fd73ca73830ccab5fa1f00ed5ed40124e2c55"),
    GitSource("https://github.com/KhronosGroup/Vulkan-Headers.git",
              "e3b1eec08173d6b825cd3ac88c885a63b621504a"),
    GitSource("https://github.com/USCiLab/cereal.git",
              "a56bad8bbb770ee266e930c95d37fff2a5be7fea"),
    FileSource("https://github.com/cpm-cmake/CPM.cmake/releases/download/v$(cpm_version)/CPM.cmake",
               "78ba32abdf798bc616bab7c73aac32a17bbd7b06ad9e26a6add69de8f3ae4791"),
]

# Bash recipe for building across all platforms
script = "cpm_version=$(cpm_version)\n" * raw"""
# Use the newer CMake from CMake_jll
apk del cmake

cd ${WORKSPACE}/srcdir/MoltenVK

# MoltenVK built for an older macOS than its Xcode project targets still compiles, but fails
# at run time there
mvk_target=$(grep -m1 -o 'MACOSX_DEPLOYMENT_TARGET = [0-9.]*' MoltenVK/MoltenVK.xcodeproj/project.pbxproj | cut -d' ' -f3)
if [[ "${mvk_target}" != "${MACOSX_DEPLOYMENT_TARGET}" ]]; then
    echo "MoltenVK targets macOS ${mvk_target}, but we build for ${MACOSX_DEPLOYMENT_TARGET}" >&2
    exit 1
fi

# MoltenVK's CMake downloads CPM and, through it, the dependencies; give it the sources above
install -Dvm 644 ../CPM.cmake ../cpm-cache/cpm/CPM_${cpm_version}.cmake

deps=(SPIRV-Cross SPIRV-Headers SPIRV-Tools Vulkan-Headers cereal)
CMAKE_FLAGS=(-DCPM_SOURCE_CACHE=${WORKSPACE}/srcdir/cpm-cache)
# Fail instead of downloading a dependency missing from the sources above
CMAKE_FLAGS+=(-DFETCHCONTENT_FULLY_DISCONNECTED=ON)
for dep in ${deps[@]}; do
    CMAKE_FLAGS+=(-DCPM_${dep}_SOURCE=${WORKSPACE}/srcdir/${dep})
done
# Log errors only by default, like the Vulkan SDK's MoltenVK rather than upstream's verbose "info";
# users can still raise it at run time with the MVK_CONFIG_LOG_LEVEL environment variable
CMAKE_FLAGS+=(-DMVK_CONFIG_LOG_LEVEL=error)

cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ${CMAKE_FLAGS[@]}
ninja -C build -j${nproc} install

# Same approach as L/Lavapipe for relocatable ICD manifest.
# The generated ICD manifest hardcodes the build-time library path. The Vulkan loader
# resolves a *relative* `library_path` against the directory of the manifest itself, which
# is what makes an artifact relocatable.
python3 - ${prefix}/etc/vulkan/icd.d/MoltenVK_icd.json ../../../lib/libMoltenVK.${dlext} <<'PYTHON'
import json, sys
manifest, lib = sys.argv[1], sys.argv[2]
with open(manifest) as f:
    icd = json.load(f)
icd["ICD"]["library_path"] = lib
with open(manifest, "w") as f:
    json.dump(icd, f, indent=4)
PYTHON
cat ${prefix}/etc/vulkan/icd.d/MoltenVK_icd.json

install_license LICENSE
# install_license installs into share/licenses/${SRC_NAME}; give each dependency its own
# subdirectory, since several name their license file LICENSE
for dep in ${deps[@]}; do
    SRC_NAME=${SRC_NAME}/${dep} install_license $(find ../${dep}/LICENSE* -type f)
done
"""

# MoltenVK features depend on the SDK it is built with (MVK_XCODE_* macros), so use the newest
# one available. The deployment target is the oldest macOS that this MoltenVK supports.
sources, script = require_macos_sdk("15.0", sources, script; deployment_target="12.0")

# MoltenVK implements Vulkan on top of Apple's Metal
platforms = filter!(Sys.isapple, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libMoltenVK", :libMoltenVK),
    FileProduct("etc/vulkan/icd.d/MoltenVK_icd.json", :MoltenVK_icd),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # SPIRV-Tools needs CMake 3.22.1
    HostBuildDependency(PackageSpec(; name="CMake_jll", version="3.22.2")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
