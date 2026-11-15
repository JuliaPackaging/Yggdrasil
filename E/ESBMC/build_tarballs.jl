# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "ESBMC"
version = v"8.0.0"

llvm_versions = [v"18.1.7"]

sources = [
    GitSource("https://github.com/esbmc/esbmc.git",
              "18a62e0b93f273dbdfcdc6e2338ad3c0b84129b8"),
    DirectorySource("./bundled"),
    # fmt has no JLL; bundle source for FetchContent
    GitSource("https://github.com/fmtlib/fmt.git",
              "407c905e45ad75fc29bf0f9bb7c5c2fd3475976f"),  # 12.1.0
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/esbmc*

# Apply cross-compilation patches
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 "${f}"
done

# On macOS, llvm-ranlib doesn't support -no_warning_for_no_symbols and -c
# flags that CMake adds on Darwin. Create a wrapper that strips them.
RANLIB_FLAGS=""
if [[ "${target}" == *-apple-darwin* ]]; then
    real_ranlib=$(which ${target}-ranlib)
    cat > /tmp/ranlib_wrapper <<WRAPPER
#!/bin/bash
args=()
for arg in "\$@"; do
    case "\$arg" in
        -no_warning_for_no_symbols|-c) ;;
        *) args+=("\$arg") ;;
    esac
done
exec "${real_ranlib}" "\${args[@]}"
WRAPPER
    chmod +x /tmp/ranlib_wrapper
    RANLIB_FLAGS="-DCMAKE_RANLIB=/tmp/ranlib_wrapper"
fi

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_Z3=ON \
    -DENABLE_SMTLIB=ON \
    -DZ3_DIR=${prefix} \
    -DLLVM_DIR=${prefix}/lib/cmake/llvm \
    -DClang_DIR=${prefix}/lib/cmake/clang \
    -DESBMC_BUNDLE_LIBC=OFF \
    -DENABLE_SOLIDITY_FRONTEND=OFF \
    -DENABLE_JIMPLE_FRONTEND=OFF \
    -DENABLE_PYTHON_FRONTEND=OFF \
    -DENABLE_GOTO_CONTRACTOR=OFF \
    -DBUILD_TESTING=OFF \
    -DENABLE_REGRESSION=OFF \
    -DDOWNLOAD_DEPENDENCIES=OFF \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
    -DFETCHCONTENT_SOURCE_DIR_FMT=${WORKSPACE}/srcdir/fmt \
    -DCMAKE_EXE_LINKER_FLAGS="-lpthread" \
    -DCCACHE_FOUND=CCACHE_FOUND-NOTFOUND \
    ${RANLIB_FLAGS}
cmake --build . --parallel ${nproc}
cmake --install .

install_license ${WORKSPACE}/srcdir/esbmc*/COPYING
"""

# ESBMC requires <cuchar> (available in libc++ from SDK 14.5+) and
# std::filesystem (available from macOS 10.15+).
sources, script = require_macos_sdk("14.5", sources, script; deployment_target="10.15")

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
        BuildDependency(PackageSpec(name=llvm_name, version=v"18.1.7+3")),
        RuntimeDependency("Clang_jll"),
        Dependency("z3_jll"; compat="4.13.3"),
        Dependency("boost_jll"; compat="1.87.0"),
        Dependency("GMP_jll"; compat="6.2.1"),
        Dependency("Zlib_jll"),
        Dependency("CompilerSupportLibraries_jll"),
        BuildDependency("nlohmann_json_jll"),
        Dependency("yaml_cpp_jll"),
    ]

    # The products that we will ensure are always built
    products = Product[
        ExecutableProduct("esbmc", :esbmc),
    ]

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = expand_cxxstring_abis(supported_platforms())
    # ESBMC is C++23; only cxx11 ABI is relevant
    filter!(p -> cxxstring_abi(p) != "cxx03", platforms)
    # disable riscv64 (not supported by LLVM_full_jll)
    filter!(p -> arch(p) != "riscv64", platforms)
    # disable aarch64 freebsd (not supported by LLVM_full_jll)
    filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
    # disable i686-linux-musl (not supported by LLVM_full_jll)
    filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
    # disable 32-bit and ARM platforms (ESBMC is 64-bit focused)
    filter!(p -> arch(p) != "i686", platforms)
    filter!(p -> arch(p) != "armv6l", platforms)
    filter!(p -> arch(p) != "armv7l", platforms)
    # disable Windows (ESBMC cross-compilation is cleaner on Unix)
    filter!(p -> !Sys.iswindows(p), platforms)

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
                   preferred_gcc_version=v"13", preferred_llvm_version=v"16",
                   julia_compat="1.12",
                   augment_platform_block)
end
