# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

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
    ArchiveSource(
        "https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
        "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/
# The build system expects this directory to be called exactly "cmake".
mv -v cmake*src cmake
cd compiler-rt*/

# We'll codesign during audit
atomic_patch -p1 ../patches/do-not-codesign.patch

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

    # Building this needs a newer SDK
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX10.14.sdk
    sed -i "s!/opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN

    # We use could use `${MACOSX_DEPLOYMENT_TARGET}` to specify the SDK version, but it's
    # set to 10.10 on x86_64, but compiler-rt requires at least 10.12 and we actually use
    # 10.12.  On aarch64 it's 11.0, but the CMake script doesn't seem to like values greater
    # than 10, so let's just use 10.12 everywhere.
    FLAGS+=(
            -DDARWIN_macosx_OVERRIDE_SDK_VERSION:STRING=10.12
            -DDARWIN_macosx_CACHED_SYSROOT=/opt/${target}/${target}/sys-root
            -DCMAKE_SYSROOT=$apple_sdk_root -DCMAKE_FRAMEWORK_PATH=$apple_sdk_root/System/Library/Frameworks
           )
fi

# Quick fix for https://github.com/llvm/llvm-project/pull/102980.
# TODO: remove it after PR is merged.
export CXXFLAGS="-D__STDC_FORMAT_MACROS=1"
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_MODULE_PATH=$(realpath ../../cmake-*.src/Modules) \
    -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${target} \
    -DCMAKE_LIBTOOL=$(which libtool) \
    "${FLAGS[@]}"

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE.TXT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Exclude failing platforms.  This package is a stop-gap solution for being able to link
# some packages on aarch64-apple-darwin, so there is little need to spend time on getting
# this to build for _all_ platforms.  The long-term plan is to have these libraries as part
# of LLVMBootstrap: https://github.com/JuliaPackaging/Yggdrasil/pull/1681
filter!(p -> arch(p) != "powerpc64le" && !(BinaryBuilder.proc_family(p) == "intel" && libc(p) == "musl"), platforms)

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
    BuildDependency(PackageSpec(name="LLVM_full_jll"; version)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8", preferred_llvm_version=version)
