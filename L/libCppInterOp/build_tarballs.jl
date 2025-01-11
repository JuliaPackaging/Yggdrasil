# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "libCppInterOp"
version = v"0.1.5"

llvm_versions = [v"18.1.7"]

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/compiler-research/CppInterOp.git", "e0546dd8fdf3fb0c7a2ba6beddaf359130d13f35"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd CppInterOp/
atomic_patch -p1 ../patches/cmake.patch
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
     -DBUILD_SHARED_LIBS=ON \
     -DLLVM_DIR=${prefix}/lib/cmake/llvm \
     -DClang_DIR=${prefix}/lib/cmake/clang \
     -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
install_license ../LICENSE.txt
"""

augment_platform_block = """
    using Base.BinaryPlatforms

    $(LLVM.augment)

    function augment_platform!(platform::Platform)
        augment_llvm!(platform)
    end"""

# determine exactly which tarballs we should build
builds = []
for llvm_version in llvm_versions, llvm_assertions in (false, true)
    # Dependencies that must be installed before this package can be built
    llvm_name = llvm_assertions ? "LLVM_full_assert_jll" : "LLVM_full_jll"
    dependencies = [
        RuntimeDependency("Clang_jll"),
        BuildDependency(PackageSpec(name=llvm_name, version=llvm_version))
    ]

    # The products that we will ensure are always built
    products = Product[
        # Clang_jll doesn't dlopen the library we depend on:
        # https://github.com/JuliaPackaging/Yggdrasil/blob/7e15aedbaca12e9c79cd1415fd03129665bcfeff/L/LLVM/common.jl#L517-L518
        # so loading the library will always fail. We fix this in CppInterOp.jl
        LibraryProduct("libCppInterOp", :libCppInterOp, dont_dlopen=true),
    ]

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = expand_cxxstring_abis(supported_platforms())

    if llvm_version >= v"15"
        # We don't build LLVM 15 for i686-linux-musl.
        filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
    end

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, llvm_assertions)

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies, products,
            platforms=[augmented_platform],
            script=script,
        ))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, sources, build.script,
                   build.platforms, build.products, build.dependencies;
                   preferred_gcc_version=v"12", julia_compat="1.7",
                   augment_platform_block)
end

# bump
