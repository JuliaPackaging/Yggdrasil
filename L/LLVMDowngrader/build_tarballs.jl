using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "LLVMDowngrader"
version = v"0.8.3"

# Build the standalone `llvm-downgrade` out-of-tree against a prebuilt LLVM
# (LLVM_full_jll), statically linked so the tool is self-contained and usable
# outside a Julia environment.
#
# Because LLVM's bitcode reader is backwards compatible (any bitcode since 3.0,
# auto-upgraded on load), this single tool ingests bitcode from any LLVM up to
# its own version and emits the legacy 5.0/7.0/14.0 formats. So it is ONE
# universal build -- not one per consumer LLVM version, and not augmented by
# llvm_version. Built against LLVM 21; track the newest LLVM as new ones land.
llvm_version = v"21.1.8+0"

sources = [
    GitSource("https://github.com/JuliaLLVM/llvm-downgrade",
              "5995472423989b01a3368611c993c9b0d6197622"),
    # We also ship the `llvm-dis` from each LLVM release whose bitcode the
    # downgrader emits (as `llvm-dis-5` / `llvm-dis-7` / `llvm-dis-14`), so the
    # downgraded bitcode can be disassembled with a matching disassembler. These
    # are built from the upstream release sources and are version-independent.
    ArchiveSource("https://releases.llvm.org/5.0.2/llvm-5.0.2.src.tar.xz",
                  "d522eda97835a9c75f0b88ddc81437e5edbb87dc2740686cb8647763855c2b3c"),
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-7.1.0/llvm-7.1.0.src.tar.xz",
                  "1bcc9b285074ded87b88faaedddb88e6b5d6c331dfcfb57d7f3393dd622b3764"),
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/llvm-14.0.6.src.tar.xz",
                  "050922ecaaca5781fdf6631ea92bc715183f202f9d2f15147226f023414f619a"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/llvm-downgrade
install_license LICENSE.TXT

# Build out-of-tree against the prebuilt LLVM from LLVM_full_jll, statically
# linking the LLVM component archives so `llvm-downgrade` has no runtime libLLVM
# dependency. The test suite needs legacy disassemblers we don't ship here, so
# it is disabled for the package build.
cmake -B build -S . -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_CROSSCOMPILING:BOOL=ON \
    -DLLVM_DIR=${prefix}/lib/cmake/llvm \
    -DLLVM_LINK_LLVM_DYLIB=OFF \
    -DLLVMDG_BUILD_TESTS=OFF
ninja -C build -j${nproc} install

# Build `llvm-dis` from the old LLVM releases whose bitcode the downgrader emits,
# so the downgraded IR can be disassembled with a matching disassembler. These are
# self-contained source builds (no LLVM_full_jll): a native llvm-tblgen/llvm-config
# bootstrap, then a cross build of just `llvm-dis` (no backends) to keep it quick.
# The ancient releases (5/7) need a couple of source tweaks to build with a modern
# CMake/toolchain (see bundled/patches); LLVM 14 builds cleanly, so the patch is
# applied only when one exists.
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

# LLVM 15+ (hence LLVM_full_jll) is built against the macOS 10.14 SDK with a
# 10.14 deployment target, so linking its objects needs the same. The
# x86_64-apple-darwin toolchain otherwise defaults to macOS 10.10, which fails to
# link the prebuilt LLVM. (No effect on non-macOS or Apple Silicon.)
sources, script = require_macos_sdk("10.14", sources, script)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("llvm-downgrade", :llvm_downgrade),
    ExecutableProduct("llvm-dis-5", :llvm_dis_5),
    ExecutableProduct("llvm-dis-7", :llvm_dis_7),
    ExecutableProduct("llvm-dis-14", :llvm_dis_14),
]

# A single, version-agnostic artifact: selected by platform alone, with no
# llvm_version augmentation.
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))
# LLVM 15+ has no i686-linux-musl build.
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)

# LLVM_full is built with ZLIB enabled (always) and ZSTD enabled (LLVM 20+), so
# the statically-linked LLVM component archives reference libz/libzstd. Because
# LLVM_full_jll is only a BuildDependency, it pulls Zlib_jll/Zstd_jll into the
# build prefix and `llvm-downgrade` links the *JLL-provided* libraries with
# `@rpath/` install names (not the system copies). BuildDependency transitive
# deps aren't bundled into the output JLL, so those @rpath references would
# dangle and dyld would fail to load `@rpath/libzstd.1.dylib` / `libz.1.dylib`
# at runtime. Declaring them as runtime Dependencies bundles the libraries and
# fixes up the rpath. (See SPIRV_LLVM_Translator / Metal_LLVM_Tools, which build
# out-of-tree against LLVM_full_jll the same way.)
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products,
               dependencies; preferred_gcc_version=v"10", julia_compat="1.6",
               lazy_artifacts=true)
