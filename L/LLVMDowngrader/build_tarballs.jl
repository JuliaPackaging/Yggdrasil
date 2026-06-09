using BinaryBuilder
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "LLVMDowngrader"
repo = "https://github.com/JuliaLLVM/llvm-downgrade"
version = v"0.8"

llvm_versions = [v"15.0.7", v"16.0.6", v"17.0.6", v"18.1.7", v"19.1.7", v"20.1.8", v"21.1.8"]

# Collection of sources required to build LLVMDowngrader. Each LLVM release has a
# matching `downgrade_release_<major>` branch in the llvm-downgrade repo; we pin
# the branch tip below. The LLVM patch version matches the latest corresponding
# LLVM_full_jll release.
sources = Dict(
    v"15.0.7" => [GitSource(repo, "6065a62d4eddd7895ec446ea5f15da4846c8544d")],
    v"16.0.6" => [GitSource(repo, "9b2c185cc8eb91130b5dbe06e09158699c4b424c")],
    v"17.0.6" => [GitSource(repo, "5ad259437f98e83b560040bdf1c84847461e7e46")],
    v"18.1.7" => [GitSource(repo, "7518b2234ae4cfed72df6eea202c108872072d98")],
    v"19.1.7" => [GitSource(repo, "bf7e42770e2889b5720eddb51284de4ebffb4bc2")],
    v"20.1.8" => [GitSource(repo, "504920cb28669caff4ce19cf31ed961c613b0ba0")],
    v"21.1.8" => [GitSource(repo, "c46b8f842b30b243eb5886a140448fbae0ef41a6")],
)

# `llvm-downgrade` can emit LLVM 5.0, 7.0 and 14.0 bitcode (`llvm-as
# --bitcode-version`). To disassemble that downgraded bitcode we also ship the
# matching `llvm-dis` from those LLVM releases (as `llvm-dis-5` / `llvm-dis-7` /
# `llvm-dis-14`). These are version- and assertion-independent, so the same
# sources are added to every build.
llvm_dis_sources = [
    ArchiveSource("https://releases.llvm.org/5.0.2/llvm-5.0.2.src.tar.xz",
                  "d522eda97835a9c75f0b88ddc81437e5edbb87dc2740686cb8647763855c2b3c"),
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-7.1.0/llvm-7.1.0.src.tar.xz",
                  "1bcc9b285074ded87b88faaedddb88e6b5d6c331dfcfb57d7f3393dd622b3764"),
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/llvm-14.0.6.src.tar.xz",
                  "050922ecaaca5781fdf6631ea92bc715183f202f9d2f15147226f023414f619a"),
    DirectorySource("./bundled"),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# Bash recipe for building across all platforms
script = raw"""
cd llvm-downgrade/llvm
LLVM_SRCDIR=$(pwd)

install_license LICENSE.TXT

# LLVM 13/14's Support/Signals.h declares `CleanupOnSignal(uintptr_t)` but does
# not `#include <cstdint>` (upstream only added that in LLVM 15). GCC >= 13 no
# longer pulls in <cstdint> transitively, so this fails to compile on toolchains
# that ship only a recent GCC -- e.g. riscv64, which has no GCC older than 14.
# Backport the include when it's missing (a no-op for LLVM 15+).
signals_h="${LLVM_SRCDIR}/include/llvm/Support/Signals.h"
if ! grep -q '#include <cstdint>' "${signals_h}"; then
    sed -i 's|^#include <string>|#include <cstdint>\n#include <string>|' "${signals_h}"
fi

# The very first thing we need to do is to build llvm-tblgen for x86_64-linux-muslc
# This is because LLVM's cross-compile setup is kind of borked, so we just
# build the tools natively ourselves, directly.  :/

# Build llvm-tblgen and llvm-config
mkdir ${WORKSPACE}/bootstrap
pushd ${WORKSPACE}/bootstrap
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=host)
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm')
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=False)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZSTD=OFF)
cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} llvm-tblgen llvm-config
popd

# Let's do the actual build within the `build` subdirectory
mkdir ${WORKSPACE}/build && cd ${WORKSPACE}/build
CMAKE_FLAGS=()

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Turn on ZLIB
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=ON)
# Turn off XML2 and ZSTD to avoid unnecessary dependencies
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZSTD=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

# Disable useless things like docs, terminfo, etc....
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=Off)
CMAKE_FLAGS+=(-DLLVM_ENABLE_TERMINFO=Off)
CMAKE_FLAGS+=(-DHAVE_HISTEDIT_H=Off)
CMAKE_FLAGS+=(-DHAVE_LIBEDIT=Off)

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} tools/llvm-as/install

# Build `llvm-dis` from the old LLVM releases whose bitcode `llvm-as` can emit,
# so the downgraded IR can be disassembled with a matching disassembler. They
# cross-compile the same way as the main build: a native llvm-tblgen/llvm-config
# bootstrap, then the actual cross build. We only build `llvm-dis` itself (no
# backends) to keep it quick. The ancient releases (5/7) need a couple of source
# tweaks to build with a modern CMake/toolchain (see bundled/patches); newer ones
# (14) build cleanly, so the patch is applied only when one exists.
build_old_llvm_dis() {
    local llvm_src="$1"
    local suffix="$2"

    # apply the build-compatibility patches, if this release needs any
    local patch="${WORKSPACE}/srcdir/patches/llvm${suffix}-cmake-policy-and-regex-guard.patch"
    if [ -f "${patch}" ]; then
        pushd "${llvm_src}"
        atomic_patch -p1 "${patch}"
        popd
    fi

    # native bootstrap: build a host llvm-tblgen/llvm-config matching this version
    mkdir -p "${WORKSPACE}/dis-bootstrap-${suffix}"
    pushd "${WORKSPACE}/dis-bootstrap-${suffix}"
    cmake -GNinja "${llvm_src}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CROSSCOMPILING=False \
        -DCMAKE_TOOLCHAIN_FILE="${CMAKE_HOST_TOOLCHAIN}" \
        -DLLVM_HOST_TRIPLE="${MACHTYPE}" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DLLVM_TARGETS_TO_BUILD="" \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -DLLVM_INCLUDE_DOCS=OFF \
        -DLLVM_ENABLE_TERMINFO=OFF \
        -DLLVM_ENABLE_ZLIB=OFF \
        -DLLVM_ENABLE_ZSTD=OFF \
        -DLLVM_ENABLE_LIBXML2=OFF
    ninja -j${nproc} llvm-tblgen llvm-config
    popd

    # cross build: just `llvm-dis`, then install + rename to `llvm-dis-${suffix}`
    mkdir -p "${WORKSPACE}/dis-build-${suffix}"
    pushd "${WORKSPACE}/dis-build-${suffix}"
    cmake -GNinja "${llvm_src}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CROSSCOMPILING:BOOL=ON \
        -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
        -DCMAKE_INSTALL_PREFIX="${prefix}" \
        -DLLVM_TABLEGEN="${WORKSPACE}/dis-bootstrap-${suffix}/bin/llvm-tblgen" \
        -DLLVM_CONFIG_PATH="${WORKSPACE}/dis-bootstrap-${suffix}/bin/llvm-config" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DLLVM_TARGETS_TO_BUILD="" \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -DLLVM_INCLUDE_DOCS=OFF \
        -DLLVM_ENABLE_TERMINFO=OFF \
        -DLLVM_ENABLE_ZLIB=OFF \
        -DLLVM_ENABLE_ZSTD=OFF \
        -DLLVM_ENABLE_LIBXML2=OFF \
        -DHAVE_HISTEDIT_H=OFF \
        -DHAVE_LIBEDIT=OFF
    ninja -j${nproc} tools/llvm-dis/install
    mv "${bindir}/llvm-dis${exeext}" "${bindir}/llvm-dis-${suffix}${exeext}"
    popd
}

build_old_llvm_dis "${WORKSPACE}/srcdir/llvm-5.0.2.src" 5
build_old_llvm_dis "${WORKSPACE}/srcdir/llvm-7.1.0.src" 7
build_old_llvm_dis "${WORKSPACE}/srcdir/llvm-14.0.6.src" 14
"""

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("llvm-as", :llvm_as),
    ExecutableProduct("llvm-dis-5", :llvm_dis_5),
    ExecutableProduct("llvm-dis-7", :llvm_dis_7),
    ExecutableProduct("llvm-dis-14", :llvm_dis_14),
]

# We ship a single build per LLVM major version. `llvm-as` is a standalone tool
# that round-trips IR/bitcode and doesn't link against the running Julia's
# libLLVM, so whether that LLVM was built with assertions is irrelevant: map both
# the assertions and non-assertions case to the same artifact.
augment_platform_block = """
    using Base.BinaryPlatforms
    function augment_platform!(platform::Platform)
        haskey(platform, "llvm_version") && return platform
        platform["llvm_version"] = string(Base.libllvm_version.major)
        return platform
    end
"""

# determine exactly which tarballs we should build
builds = []
for llvm_version in llvm_versions
    # We build LLVM from the downgrade source, so there's no LLVM_full_jll build
    # dependency; only Zlib is needed (the build configures LLVM_ENABLE_ZLIB=ON).
    dependencies = [
        Dependency("Zlib_jll")
    ]

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, false)

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies,
            sources=[sources[llvm_version]; llvm_dis_sources],
            platforms=[augmented_platform],
            preferred_gcc_version=(llvm_version >= v"16" ? v"10" : v"7")
        ))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` and `--deploy` should only be passed to the final `build_tarballs` invocation
non_reg_ARGS = filter(non_platform_ARGS) do arg
    arg != "--register" && !startswith(arg, "--deploy")
end

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, products, build.dependencies;
                   build.preferred_gcc_version, julia_compat="1.6",
                   augment_platform_block, lazy_artifacts=true)
end
