# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "IREE"
version = v"0.0.599" # corresponds to tag `candidate-20230731.599`, last release with LLVM 17

sources = [
    GitSource("https://github.com/openxla/iree.git", "cf5d348e78eaa893589d8f8553ddc967e38fa2cf"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

llvm_versions = [v"17.0.6+1"]

script = raw"""
cd $WORKSPACE/srcdir/iree

# skip fetching unused submodules
git \
    -c submodule."third_party/llvm-project".update=none \
    -c submodule."third_party/torch-mlir".update=none \
    -c submodule."third_party/pybind11".update=none \
    -c submodule."third_party/tracy".update=none \
    -c submodule."third_party/webgpu-headers".update=none \
    -c submodule."third_party/pybind11".update=none \
    -c submodule."third_party/tracy".update=none \
    submodule update --init --recursive

# apply patch
atomic_patch -p1 ../patches/fix-missing-link-to-hal_executable_loader.patch
atomic_patch -p1 ../patches/fix-import-host-binaries-on-compiler-crosscompile.patch

# binaries needed by target pipeline but to be run on host
rm ${prefix}/tools/mlir-tblgen ${prefix}/tools/mlir-pdll ${prefix}/tools/clang-17 ${prefix}/tools/llvm-link
ln -s ${host_prefix}/tools/mlir-tblgen ${prefix}/tools/mlir-tblgen
ln -s ${host_prefix}/tools/mlir-pdll ${prefix}/tools/mlir-pdll
ln -s ${host_prefix}/tools/clang-17 ${prefix}/tools/clang-17
ln -s ${host_prefix}/tools/llvm-link ${prefix}/tools/llvm-link

rm /opt/x86_64-linux-musl/x86_64-linux-musl/sys-root/usr/local
ln -s ${host_prefix} /opt/x86_64-linux-musl/x86_64-linux-musl/sys-root/usr/local

# 1. build IREE for host
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${host_prefix})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Debug)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})

CMAKE_FLAGS+=(-DIREE_ERROR_ON_MISSING_SUBMODULES=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_COMPILER=ON)
CMAKE_FLAGS+=(-DIREE_BUILD_TESTS=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_DOCS=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_SAMPLES=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_PYTHON_BINDINGS=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_TRACY=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_BUNDLED_LLVM=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_BINDINGS_TFLITE=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_BINDINGS_TFLITE_JAVA=OFF)

CMAKE_FLAGS+=(-DIREE_ENABLE_CPUINFO=OFF)

CMAKE_FLAGS+=(-DIREE_CUDA_AVAILABLE=OFF)
CMAKE_FLAGS+=(-DIREE_HAL_DRIVER_CUDA=OFF)
CMAKE_FLAGS+=(-DIREE_HAL_DRIVER_VULKAN=OFF)

CMAKE_FLAGS+=(-DIREE_HAL_EXECUTABLE_LOADER_EMBEDDED_ELF=OFF)
CMAKE_FLAGS+=(-DIREE_HAL_EXECUTABLE_LOADER_SYSTEM_LIBRARY=OFF)

CMAKE_FLAGS+=(-DIREE_HAL_EXECUTABLE_PLUGIN_EMBEDDED_ELF=OFF)
CMAKE_FLAGS+=(-DIREE_HAL_EXECUTABLE_PLUGIN_SYSTEM_LIBRARY=OFF)

CMAKE_FLAGS+=(-DIREE_INPUT_STABLEHLO=OFF)
CMAKE_FLAGS+=(-DIREE_INPUT_TORCH=OFF)
CMAKE_FLAGS+=(-DIREE_INPUT_TOSA=OFF)

CMAKE_FLAGS+=(-DIREE_TARGET_BACKEND_DEFAULTS=OFF)

CMAKE_FLAGS+=(-DLLVM_DIR=${host_prefix}/lib/cmake/llvm)
# disable LLVM assertions due to bug https://github.com/llvm/llvm-project/issues/73248
CMAKE_FLAGS+=(-DLLVM_ENABLE_ASSERTIONS=OFF) 
CMAKE_FLAGS+=(-DLLVM_LINK_LLVM_DYLIB=ON)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LLD="OFF")
CMAKE_FLAGS+=(-DLLVM_EXTERNAL_LIT=${host_prefix}/tools/lit/lit.py)

cmake -B build/host -S . -GNinja ${CMAKE_FLAGS[@]}
# ninja -C build/host -j ${nproc} iree-tblgen iree-flatcc-cli generate_embed_data iree-compile iree-opt iree-run-mlir iree-run-module
# install -c \
#     build/host/tools/iree-tblgen \
#     build/host/build_tools/third_party/flatcc/iree-flatcc-cli \
#     build/host/build_tools/embed_data/generate_embed_data \
#     build/host/tools/iree-compile \
#     build/host/tools/iree-opt \
#     build/host/tools/iree-run-mlir \
#     build/host/tools/iree-run-module \
#     ${host_prefix}/bin
cmake --build build/host --parallel ${nproc} --target install

# 2. build IREE for target
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

CMAKE_FLAGS+=(-DIREE_HOST_BIN_DIR=${host_prefix}/bin)

CMAKE_FLAGS+=(-DIREE_ERROR_ON_MISSING_SUBMODULES=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_COMPILER=ON)
CMAKE_FLAGS+=(-DIREE_BUILD_TESTS=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_DOCS=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_SAMPLES=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_PYTHON_BINDINGS=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_TRACY=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_BUNDLED_LLVM=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_BINDINGS_TFLITE=OFF)
CMAKE_FLAGS+=(-DIREE_BUILD_BINDINGS_TFLITE_JAVA=OFF)
CMAKE_FLAGS+=(-DIREE_TARGET_BACKEND_LLVM_CPU=ON)

# disable cpuinfo for now
CMAKE_FLAGS+=(-DIREE_ENABLE_CPUINFO=OFF)

# disable for now
CMAKE_FLAGS+=(-DIREE_CUDA_AVAILABLE=OFF)

# input MLIR dialects
CMAKE_FLAGS+=(-DIREE_INPUT_STABLEHLO=ON)
CMAKE_FLAGS+=(-DIREE_INPUT_TORCH=OFF)
CMAKE_FLAGS+=(-DIREE_INPUT_TOSA=ON)

# avoid checks when cross-compiling
CMAKE_FLAGS+=(-DHAVE_THREAD_SAFETY_ATTRIBUTES=0)
CMAKE_FLAGS+=(-DHAVE_STD_REGEX=0)
CMAKE_FLAGS+=(-DHAVE_POSIX_REGEX=0)
CMAKE_FLAGS+=(-DHAVE_STEADY_CLOCK=0)

CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)

CMAKE_FLAGS+=(-DLLVM_DIR=${prefix}/lib/cmake/llvm)
CMAKE_FLAGS+=(-DLLVM_ENABLE_ASSERTIONS=OFF)
CMAKE_FLAGS+=(-DLLVM_LINK_LLVM_DYLIB=ON)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LLD="OFF")
CMAKE_FLAGS+=(-DLLVM_EXTERNAL_LIT=${prefix}/tools/lit/lit.py)

CMAKE_FLAGS+=(-DMLIR_DIR=${prefix}/lib/cmake/mlir)

cmake -B build/target -S . -GNinja ${CMAKE_FLAGS[@]}

# generate iree-tblgen
# ninja -C build/target -j ${nproc} iree-tblgen

# rename it and link host's version
# mv build/target/tools/iree-tblgen build/target/tools/iree-tblgen-target
# ln -s ${host_prefix}/bin/iree-tblgen build/target/tools/iree-tblgen

cmake --build build/target --parallel ${nproc} --target install
# rm build/target/tools/iree-tblgen
# mv build/target/tools/iree-tblgen-target build/target/tools/iree-tblgen
# install -c build/target/tools/iree-tblgen ${prefix}/bin
"""

platforms = supported_platforms()
filter!(==(64) ∘ wordsize, platforms)
filter!(!=("powerpc64le") ∘ arch, platforms)
filter!(!Sys.iswindows, platforms)
platforms = expand_cxxstring_abis(platforms)

products = Product[
    ExecutableProduct("iree-run-module", :iree_run_module)
]

augment_platform_block = """
    using Base.BinaryPlatforms
    $(LLVM.augment)
    function augment_platform!(platform::Platform)
        augment_llvm!(platform)
    end"""

builds = []
for llvm_version in llvm_versions

    dependencies = [
        Dependency("MLIR_jll", llvm_version),
        BuildDependency(PackageSpec(name="LLVM_jll", version=llvm_version)),
        BuildDependency(PackageSpec(name="LLD_jll", version=llvm_version)),
        BuildDependency(PackageSpec(name="Clang_jll", version=llvm_version)),
        HostBuildDependency(PackageSpec(name="MLIR_jll", version=llvm_version)),
        HostBuildDependency(PackageSpec(name="LLVM_jll", version=llvm_version)),
        HostBuildDependency(PackageSpec(name="LLD_jll", version=llvm_version)),
        HostBuildDependency(PackageSpec(name="Clang_jll", version=llvm_version)),
    ]

    for platform in platforms
        augmented_platform = deepcopy(platform)
        llvm_assertions = false
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, llvm_assertions)

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (; dependencies, platforms=[augmented_platform]))
    end
end

for (i, build) in enumerate(builds)
    build_tarballs(ARGS,
        name,
        version,
        sources,
        script,
        build.platforms,
        products,
        build.dependencies;
        julia_compat="1.11",
        preferred_gcc_version=v"13",
        augment_platform_block,
        lazy_artifacts=true)
end