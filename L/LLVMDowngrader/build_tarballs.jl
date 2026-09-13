using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "LLVMDowngrader"
version = v"0.11.0"

# Build `libllvm_downgrade`, a shared library with a small C API (see
# include/llvm-downgrade.h upstream) over the legacy bitcode writers,
# replacing the `llvm-downgrade` executable. It is built out-of-tree
# against a prebuilt LLVM (LLVM_full_jll), statically linked with every LLVM
# symbol hidden, so consumers (GPUCompiler, AMDGPU.jl, Metal.jl) can call it
# in-process next to Julia's own LLVM instead of spawning the tool.
#
# Because LLVM's bitcode reader is backwards compatible (any bitcode since 3.0,
# auto-upgraded on load), this single tool ingests bitcode from any LLVM up to
# its own version and emits the legacy 5.0/7.0/14.0/15.0/18.0 formats. So it is ONE
# universal build -- not one per consumer LLVM version, and not augmented by
# llvm_version. Built against LLVM 23; track the newest LLVM as new ones land.
llvm_version = v"23.1.1+0"

sources = [
    GitSource("https://github.com/JuliaLLVM/llvm-downgrade",
              "4244e2a1ec56dd9c714755453ba840a48a0b5ee5"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/llvm-downgrade
install_license LICENSE.TXT

# Build out-of-tree against the prebuilt LLVM from LLVM_full_jll, statically
# linking the LLVM component archives so `libllvm_downgrade` has no runtime
# libLLVM dependency (and hides every LLVM symbol, see upstream's CMakeLists).
# Only the library is shipped: the `llvm-downgrade` tool is a thin driver over
# the same API, and a few lines of Julia (or C, against the installed header)
# reproduce it. The test suite needs legacy disassemblers we don't ship here,
# so it is disabled for the package build.
# On Windows, build with the Clang/LLD toolchain, like LLVM_full_jll and the
# GPU back-end libraries. A DLL linked by GNU ld gets a 32-bit-range image base
# without ASLR, and when the loader has to relocate it (its preferred base is
# occupied, e.g. by Julia 1.10's libLLVMExtra), the first thread-local access
# inside the library faults on Julia 1.10's mingw runtime
# (JuliaGPU/GPUCompiler.jl#930). LLD's output (0x180000000 base, dynamic base)
# is relocated on every load and works.
if [[ "${target}" == *mingw* ]]; then
    TOOLCHAIN=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake
    CXX_FLAGS="-pthread"
else
    TOOLCHAIN=${CMAKE_TARGET_TOOLCHAIN}
    CXX_FLAGS=""
fi
cmake -B build -S . -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN} \
    -DCMAKE_CXX_FLAGS="${CXX_FLAGS}" \
    -DCMAKE_CROSSCOMPILING:BOOL=ON \
    -DLLVM_DIR=${prefix}/lib/cmake/llvm \
    -DLLVM_LINK_LLVM_DYLIB=OFF \
    -DLLVMDG_BUILD_TOOL=OFF \
    -DLLVMDG_BUILD_TESTS=OFF
ninja -C build -j${nproc} install

# Show what got exported: only the LLVMDG* API, and (on ELF) no STB_GNU_UNIQUE
# symbols, which would defeat the isolation.
if [[ "${target}" == *-linux-* || "${target}" == *-freebsd* ]]; then
    echo "exported symbols:"; nm -D --defined-only ${libdir}/libllvm_downgrade.${dlext} | grep -v ' [wv] '
    echo "STB_GNU_UNIQUE symbols: $(readelf -Ws ${libdir}/libllvm_downgrade.${dlext} | grep -c UNIQUE)"
elif [[ "${target}" == *-apple-* ]]; then
    echo "exported symbols:"; nm -gU ${libdir}/libllvm_downgrade.${dlext}
fi
"""

# LLVM_full_jll 22+ is built against the macOS 11.0 SDK with an 11.0 deployment
# target, and LLVM 23's headers no longer compile against the older SDK's libc++.
# The x86_64-apple-darwin toolchain otherwise defaults to macOS 10.10, which fails
# to link the prebuilt LLVM. (No effect on non-macOS or Apple Silicon.)
sources, script = require_macos_sdk("11.0", sources, script)

# The products that we will ensure are always built. The library is not
# dlopen'ed at `__init__` time; the first `ccall` into it loads it on demand.
# The legacy `llvm-dis-*` disassemblers are no longer shipped: their only
# consumer was the textual form of Metal's AIR, which Julia's own LLVM can
# produce by parsing the downgraded bitcode.
products = Product[
    LibraryProduct("libllvm_downgrade", :libllvm_downgrade; dont_dlopen=true),
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
