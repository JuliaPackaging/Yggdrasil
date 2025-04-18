# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "x265"
version = v"4.1"

# NOTE: The release notes for version 4.0 do not mention any
# incompatibility with version 3.6. Packages currently using 3.6 might
# try building against 4.0.

# Collection of sources required to build x265
sources = [
    GitSource("https://bitbucket.org/multicoreware/x265_git.git", "32e25ffcf810c5fe284901859b369270824c4596"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/x265_git

# x265 builds for multiple architectures, using `-march` and `-mcpu`
# options, and then dispatches at run time. To support that, we need to
# (1) Disable the checks for `-march` and `-mcpu` in the compiler wrappers
# (2) Don't set `-march` or `-mcpu` in the compiler wrappers
# We still can't have `-march=native` or `-mpcu=native`.

# Disable `-march` checks in our compiler wrappers
sed -i 's/"-march="/this_will_never_match/g' $(dirname $(which gcc))/*
# Don't set a default architecture or cpu in our compiler wrappers, x265 wants to do that
sed -i 's/-m\(arch\|cpu\)=[-+.0-9A-Za-z_]*//g' $(dirname $(which gcc))/*

# Remove `-march=native` and `-mcpu=native` flags in x265
sed -i 's/-m\(arch\|cpu\)=native//g' source/CMakeLists.txt source/dynamicHDR10/CMakeLists.txt

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/neon.patch

cmake -S source -B build \
    -DCMAKE_INSTALL_PREFIX="${prefix}" \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DENABLE_PIC=ON \
    -DENABLE_SHARED=ON
cmake --build build --parallel ${nproc}
cmake --install build
# Remove the large static archive
rm -v ${prefix}/lib/libx265.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("x265", :x265),
    LibraryProduct("libx265", :libx265)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We need `nasm` for x86_64
    HostBuildDependency("NASM_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need GCC 12 to support the aarch64 assembler intrinsics.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"12")
