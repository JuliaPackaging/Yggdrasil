using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "SPIRV_LLVM_Translator_unified"
repo = "https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git"
version = v"0.7.1"

llvm_versions = [v"15.0.7", v"16.0.6", v"17.0.6", v"18.1.7", v"19.1.1"]

# Collection of sources required to build SPIRV_LLVM_Translator
sources = Dict(
    v"15.0.7" => [GitSource(repo, "4b96335944e70032f4dfa4807d9c5683eaabdae5")],
    v"16.0.6" => [GitSource(repo, "b786f8c31eead5788ac8ca33ccedf29a4a7faedf")],
    v"17.0.6" => [GitSource(repo, "27bbf0fa898b6945dbd097dfd1e87b4f4becb19a")],
    v"18.1.7" => [GitSource(repo, "7515735e387c65cbb7821a78f122cfd89115a779")],
    v"19.1.1" => [GitSource(repo, "90a976491d3847657396456e0e94d7dc48d35996")],
)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))
filter!(p -> libc(p) != "musl", platforms) # missing LLVM_full+asserts
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms) # missing LLVM_full

# Bash recipe for building across all platforms
get_script(llvm_version) = raw"""
cd SPIRV-LLVM-Translator
install_license LICENSE.TXT

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

# Tell CMake where LLVM is
CMAKE_FLAGS+=(-DLLVM_DIR="${prefix}/lib/cmake/llvm")

# Build the library
CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)

# Use our LLVM version
CMAKE_FLAGS+=(-DBASE_LLVM_VERSION=""" * string(Base.thisminor(llvm_version)) * raw""")

# Suppress certain errors
CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-Wno-enum-constexpr-conversion")

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} llvm-spirv install
install -Dm755 build/tools/llvm-spirv/llvm-spirv${exeext} -t ${bindir}
"""

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libLLVMSPIRVLib", "LLVMSPIRVLib"], :libLLVMSPIRV),
    ExecutableProduct("llvm-spirv", :llvm_spirv),
]

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
        BuildDependency(PackageSpec(name=llvm_name, version=llvm_version))
    ]

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, llvm_assertions)

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies,
            sources=sources[llvm_version],
            platforms=[augmented_platform],
            script=get_script(llvm_version)
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
                   name, version, build.sources, build.script,
                   build.platforms, products, build.dependencies;
                   preferred_gcc_version=v"10", julia_compat="1.6",
                   augment_platform_block, lazy_artifacts=true)
end
