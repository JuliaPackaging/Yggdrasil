# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "StableHLO"
version = v"0.14.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/openxla/stablehlo.git", "8816d0581d9a5fb7d212affef858e991a349ad6b"),
    DirectorySource(joinpath(@__DIR__, "bundled/")),
]

llvm_versions = [v"17.0.6"]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/stablehlo

# apply patch to produce shared libraries
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/set-shared-mlir-library.patch

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
CMAKE_FLAGS+=(-DCMAKE_C_COMPILER=clang)
CMAKE_FLAGS+=(-DCMAKE_CXX_COMPILER=clang++)

CMAKE_FLAGS+=(-DLLVM_DIR=${prefix}/lib/cmake/llvm)
CMAKE_FLAGS+=(-DLLVM_ENABLE_ASSERTIONS=OFF)
CMAKE_FLAGS+=(-DLLVM_LINK_LLVM_DYLIB=ON)

CMAKE_FLAGS+=(-DMLIR_DIR=${prefix}/lib/cmake/mlir)

CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)

if [[ "$(uname)" != "Darwin" ]]; then
    CMAKE_FLAGS+=(-DLLVM_ENABLE_LLD="ON")
else
    CMAKE_FLAGS+=(-DLLVM_ENABLE_LLD="OFF")
fi

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("stablehlo-opt", :stablehlo_opt),
    ExecutableProduct("stablehlo-translate", :stablehlo_translate),
    LibraryProduct("libStablehloCAPI", :libStablehloCAPI),
    LibraryProduct("libStablehloPortableApi", :libStablehloPortableApi),
    LibraryProduct("libStablehloTOSATransforms", :libStablehloTOSATransforms),
    LibraryProduct("libStablehloBase", :libStablehloBase),
    LibraryProduct("libStablehloBroadcastUtils", :libStablehloBroadcastUtils),
    LibraryProduct("libChloOps", :libChloOps),
    LibraryProduct("libStablehloRegister", :libStablehloRegister),
    LibraryProduct("libStablehloAssemblyFormat", :libStablehloAssemblyFormat),
    LibraryProduct("libStablehloSerialization", :libStablehloSerialization),
    LibraryProduct("libStablehloTypeInference", :libStablehloTypeInference),
    LibraryProduct("libStablehloOps", :libStablehloOps),
    LibraryProduct("libVersion", :libVersion),
    LibraryProduct("libVhloOps", :libVhloOps),
    LibraryProduct("libVhloTypes", :libVhloTypes),
    LibraryProduct("libChloCAPI", :libChloCAPI),
    LibraryProduct("libStablehloCAPI", :libStablehloCAPI),
    LibraryProduct("libVhloCAPI", :libVhloCAPI),
    LibraryProduct("libStablehloReferenceAxes", :libStablehloReferenceAxes),
    LibraryProduct("libStablehloReferenceElement", :libStablehloReferenceElement),
    LibraryProduct("libStablehloReferenceIndex", :libStablehloReferenceIndex),
    LibraryProduct("libStablehloReferenceInterpreterValue", :libStablehloReferenceInterpreterValue),
    LibraryProduct("libStablehloReferenceOps", :libStablehloReferenceOps),
    LibraryProduct("libStablehloReferenceScope", :libStablehloReferenceScope),
    LibraryProduct("libStablehloReferenceTensor", :libStablehloReferenceTensor),
    LibraryProduct("libStablehloReferenceToken", :libStablehloReferenceToken),
    LibraryProduct("libStablehloReferenceTypes", :libStablehloReferenceTypes),
    LibraryProduct("libStablehloPasses", :libStablehloPasses),
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
        RuntimeDependency("MLIR_jll"; compat=string(llvm_version.major)),
        HostBuildDependency(PackageSpec(name="MLIR_jll", version=llvm_version)),
        BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
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
        julia_compat="1.10",
        preferred_gcc_version=v"8",
        preferred_llvm_version=v"17",
        augment_platform_block,
        lazy_artifacts=true)
end
