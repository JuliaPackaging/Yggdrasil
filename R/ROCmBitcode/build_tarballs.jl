using Base.BinaryPlatforms
using BinaryBuilder
using Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

devlibs_source = "https://github.com/RadeonOpenCompute/ROCm-Device-Libs.git"
devlibs_tags = Dict(
    v"5.5.1" => "49dd756ee374d648beb3ecd593f419db425ef621",
    v"5.6.1" => "2b9acb09a3808d80c61ab89235a7cf487f52e955")

name = "ROCmBitcode"
# Version of our artifact.
version = v"0.0.1"

# TODO support more than 1.10.
# For what LLVM versions to build => what ROCm versions.
llvm_versions = Dict(v"15.0.7" => [v"5.5.1", v"5.6.1"])
rocm_patches = Dict(
    v"15.0.7" => Dict(
        v"5.6.1" => raw"""
        atomic_patch -p1 $WORKSPACE/srcdir/patches/irif-no-memory-rw.patch
        atomic_patch -p1 $WORKSPACE/srcdir/patches/ocml-builtins-rename.patch
        atomic_patch -p1 $WORKSPACE/srcdir/patches/ockl-no-ballot.patch
        """,
    ),
)

# TODO build using (llvm_version, rocm_llvm) pair.
# Using fixed version of ROCm LLVM which still uses LLVM 15.
rocm_llvm = v"5.4.4"

platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
]

script = raw"""
CC=${WORKSPACE}/srcdir/rocm-clang \
CXX=${WORKSPACE}/srcdir/rocm-clang++ \
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DLLVM_DIR=${prefix}/llvm/lib/cmake/llvm \
    -DLLD_DIR=${prefix}/llvm/lib/cmake/lld \
    -DClang_DIR=${prefix}/llvm/lib/cmake/clang \
    ..

make -j${nproc}
make install

install_license ${WORKSPACE}/srcdir/ROCm-Device-Libs*/LICENSE.TXT
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(LLVM.augment)
    function augment_platform!(platform::Platform)
        augment_llvm!(platform)
    end"""

builds = []
for (llvm_version, rocm_versions) in llvm_versions, rocm_version in rocm_versions
    rv = "rocm_$(rocm_version.major)_$(rocm_version.minor)"
    lv = "llvm_$(llvm_version.major)"
    products = [FileProduct("amdgcn/bitcode/", Symbol("bitcode_$(lv)_$(rv)"))]

    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version=rocm_llvm)),
        BuildDependency(PackageSpec(; name="rocm_cmake_jll", version=rocm_version)),
        Dependency("Zlib_jll"),
    ]
    sources = [
        GitSource(devlibs_source, devlibs_tags[rocm_version]),
        DirectorySource("./scripts")]
    # If there are any patches, add them.
    if llvm_version in keys(rocm_patches) && rocm_version in keys(rocm_patches[llvm_version])
        push!(sources, DirectorySource("./bundled_$(lv)_$(rv)"))
    end

    buildscript = raw"""
    cd ${WORKSPACE}/srcdir/ROCm-Device-Libs*/
    """ * get(rocm_patches, rocm_version, "") *
    raw"""
    mkdir build && cd build
    """ * script

    # Augment platform with LLVM & ROCm versions.
    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(
            llvm_version, false #= llvm assertions =#)
        augmented_platform["rocm_version"] = string(rocm_version)
        push!(builds, (;
            dependencies, products, buildscript, sources,
            platforms=[augmented_platform]))
    end
end

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", ARGS)
for (i, build) in enumerate(builds)
    build_tarballs(
        i == lastindex(builds) ? ARGS : non_reg_ARGS,
        name, version, build.sources, build.buildscript,
        build.platforms, build.products, build.dependencies;
        preferred_gcc_version=v"8", julia_compat="1.9", augment_platform_block)
end
