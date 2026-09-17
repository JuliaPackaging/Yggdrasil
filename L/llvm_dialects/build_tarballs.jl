using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "llvm_dialects"
repo = "https://github.com/JuliaLang/llvm-dialects.git"
version = v"0.1.0"

llvm_versions = [v"21.1.8+0", v"22.1.8+0"]

sources = [
    GitSource(repo, "dfdfc4beb4f950212736489cf6cc47b7077eaa32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd llvm-dialects

CMAKE_FLAGS=()
# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
if [[ "${target}" == *mingw* ]]; then
    # LLVM_full is built with Clang/LLD on Windows (see L/LLVM/common.jl);
    # use the same toolchain here.
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake)
else
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
fi
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
# Tell CMake where LLVM is
CMAKE_FLAGS+=(-DLLVM_DIR="${prefix}/lib/cmake/llvm")
# Force linking against shared lib
CMAKE_FLAGS+=(-DLLVM_LINK_LLVM_DYLIB=ON)
# The static library gets linked into libjulia-codegen
CMAKE_FLAGS+=(-DCMAKE_POSITION_INDEPENDENT_CODE=ON)
cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}

# There are no install rules; build the two products we ship and install
# them (and the headers, including the *.td dialect definitions) manually.
ninja -C build -j ${nproc} llvm-dialects-tblgen llvm_dialects

install -Dvm 755 "build/llvm-dialects-tblgen${exeext}" "${bindir}/llvm-dialects-tblgen${exeext}"
install -Dvm 644 build/libllvm_dialects.a "${prefix}/lib/libllvm_dialects.a"
mkdir -p ${includedir}
cp -rv include/llvm-dialects ${includedir}/

install_license LICENSE
"""

# LLVM 15+ requires macOS SDK 10.14.
sources, script = require_macos_sdk("10.14", sources, script)

augment_platform_block = """
    using Base.BinaryPlatforms
    $(LLVM.augment)
    augment_platform!(platform::Platform) = augment_llvm!(platform)
"""

# determine exactly which tarballs we should build
builds = []
for llvm_version in llvm_versions, llvm_assertions in (false, true)
    # Dependencies that must be installed before this package can be built
    llvm_name = llvm_assertions ? "LLVM_full_assert_jll" : "LLVM_full_jll"
    dependencies = [
        BuildDependency(PackageSpec(name=llvm_name, version=llvm_version))
    ]

    # The products that we will ensure are always built
    products = Product[
        ExecutableProduct("llvm-dialects-tblgen", :llvm_dialects_tblgen),
        FileProduct("lib/libllvm_dialects.a", :libllvm_dialects),
    ]

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))
    ## we don't build LLVM for i686-linux-musl.
    filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, llvm_assertions)

        platform_sources = BinaryBuilder.AbstractSource[sources...]

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies, products, sources=platform_sources,
            platforms=[augmented_platform],
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
                   name, version, build.sources, script,
                   build.platforms, build.products, build.dependencies;
                   preferred_gcc_version=v"10", julia_compat="1.6",
                   augment_platform_block, lazy_artifacts=true)
end
