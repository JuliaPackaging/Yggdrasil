# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "LLVMCompilerRT"
version = v"17.0.6"

sources = [
    ArchiveSource(
        "https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/compiler-rt-$(version).src.tar.xz",
        "11b8d09dcf92a0f91c5c82defb5ad9ff4acf5cf073a80c317204baa922d136b4"
    ),
    ArchiveSource(
        "https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/cmake-$(version).src.tar.xz",
        "807f069c54dc20cb47b21c1f6acafdd9c649f3ae015609040d6182cab01140f4"
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# The build system expects this directory to be called exactly "cmake".
mv -v cmake*src cmake

cd compiler-rt*

# We'll codesign during audit
atomic_patch -p1 ../patches/do-not-codesign.patch

# We don't want `-march` on aarch64
atomic_patch -p1 ../patches/aarch64-no-march.patch

# We don't need musl's <asm/ptrace.h> on aarch64
atomic_patch -p1 ../patches/aarch64-no-asm-ptrace.patch

FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    # Fake `PlistBuddy` to make detection of aarch64 support work
    mkdir -p /usr/libexec
    cat > /usr/libexec/PlistBuddy << EOF
#!/bin/bash

if [[ "${target}" == aarch64-* ]]; then
    echo " arm64"
else
    echo " $(uname -m)"
fi
EOF
    chmod +x /usr/libexec/PlistBuddy

    # Create official Apple-blessed `xcrun`
    cat > $(which xcrun) << EOF
#!/bin/bash
if [[ "\${@}" == *"--show-sdk-path"* ]]; then
   echo /opt/${target}/${target}/sys-root
elif [[ "\${@}" == *"--show-sdk-version"* ]]; then
   echo 10.12
else
   exec "\${@}"
fi
EOF
fi

FLAGS+=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_MODULE_PATH=$(realpath ../../cmake-*.src/Modules)
    -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${target}
    -DCMAKE_LIBTOOL=$(which libtool)
)

if [[ ${target} == x86_64-linux-gnu* ]]; then
   FLAGS+=(
        -DCOMPILER_RT_BUILD_SANITIZERS=ON
        -DCOMPILER_RT_SANITIZERS_TO_BUILD=msan
   )
fi

# Quick fix for https://github.com/llvm/llvm-project/pull/102980.
# Remove this patch for LLVM versions which include this patch -- probably LLVM 19 or 20.
export CXXFLAGS="-D__STDC_FORMAT_MACROS=1"

cmake -Bbuild "${FLAGS[@]}"
cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE.TXT
"""

sources, script = require_macos_sdk("10.14", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Exclude failing platforms.  This package is a stop-gap solution for being able to link
# some packages on aarch64-apple-darwin, so there is little need to spend time on getting
# this to build for _all_ platforms.  The long-term plan is to have these libraries as part
# of LLVMBootstrap: https://github.com/JuliaPackaging/Yggdrasil/pull/1681
filter!(platforms) do p
    # Something doesn't work
    arch(p) in ["aarch64", "i686", "x86_64"] && libc(p) == "musl" && return false
    # LLVM 17 has not been built for aarch64-unknown-freebsd
    arch(p) == "aarch64" && Sys.isfreebsd(p) && return false
    # LLVM 17 has not been built for riscv64
    arch(p) == "riscv64" && return false
    return true
end

# The products that we will ensure are always built
products = LibraryProduct[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency("XML2_jll"; compat="~2.13.6"),
    Dependency("Zlib_jll"),
    BuildDependency(PackageSpec(name="LLVM_full_jll"; version=string(version))),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8", preferred_llvm_version=version)
