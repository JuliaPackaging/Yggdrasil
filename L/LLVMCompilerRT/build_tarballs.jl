# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LLVMCompilerRT"
version = v"13.0.1"

sources = [
    ArchiveSource(
        "https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/compiler-rt-$(version).src.tar.xz",
        "7b33955031f9a9c5d63077dedb0f99d77e4e7c996266952c1cec55626dca5dfc"
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/compiler-rt*/

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

    # We use could use `${MACOSX_DEPLOYMENT_TARGET}` to specify the SDK version, but it's
    # set to 10.10 on x86_64, but compiler-rt requires at least 10.12 and we actually use
    # 10.12.  On aarch64 it's 11.0, but the CMake script doesn't seem to like values greater
    # than 10, so let's just use 10.12 everywhere.
    FLAGS+=(
            -DDARWIN_macosx_OVERRIDE_SDK_VERSION:STRING=10.12
            -DDARWIN_macosx_CACHED_SYSROOT=/opt/${target}/${target}/sys-root
           )
fi

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_BUILD_TYPE=Release \
    "${FLAGS[@]}" \
    ..
make -j${nproc}
make install
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
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8", preferred_llvm_version=version)
