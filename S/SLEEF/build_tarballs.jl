# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))          # should_build_platform
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "SLEEF"
version = v"3.9.0"

# Collection of sources required to complete build. The macOS 14.5 SDK (SLEEF needs C++20)
# is appended below via `get_macos_sdk_sources`; the script installs it non-destructively.
sources = [
    GitSource("https://github.com/shibatch/sleef.git", "906ca7512ee483296780a81a21b9ca715d40dfe1"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms.
script = raw"""
if [[ "${target}" == *-apple-darwin* ]]; then
    # SLEEF needs the macOS 14.5 SDK (for C++20). The toolchain's sys-root lives on a
    # read-only overlay where removing/replacing the System tree fails with I/O errors (and
    # merging the SDK on top hits symlink-vs-directory conflicts). So assemble a writable
    # scratch sysroot -- a copy of the real one (which keeps the toolchain's C++ headers and
    # the OpenMP runtime that libsleefdft needs) with System replaced by the newer SDK -- and
    # point the cross toolchain at it. Mirrors the non-destructive setup in P/pocl/common.jl.
    apple_sysroot=$WORKSPACE/srcdir/sysroot
    cp -a /opt/${target}/${target}/sys-root $apple_sysroot
    tar --extract --file=${WORKSPACE}/srcdir/MacOSX14.5.sdk.tar.xz \
        --directory=$WORKSPACE/srcdir --warning=no-unknown-keyword \
        MacOSX14.5.sdk/System MacOSX14.5.sdk/usr
    # Drop the dirs the SDK will provide so the overlay can't hit symlink-vs-directory /
    # "File exists" conflicts (the toolchain's libc++ headers vs the SDK's, and libxml2).
    rm -rf $apple_sysroot/System $apple_sysroot/usr/include/c++ $apple_sysroot/usr/include/libxml2
    cp -ra $WORKSPACE/srcdir/MacOSX14.5.sdk/System $apple_sysroot/.
    cp -ra $WORKSPACE/srcdir/MacOSX14.5.sdk/usr/* $apple_sysroot/usr/.
    # redirect every sys-root reference (--sysroot / -isysroot) at the scratch copy
    sed -i "s!/opt/${target}/${target}/sys-root!$apple_sysroot!g" ${CMAKE_TARGET_TOOLCHAIN}
    sed -i "s!/opt/${target}/${target}/sys-root!$apple_sysroot!g" $(find /opt/bin/${bb_full_target} -type f) 2>/dev/null || true
    export MACOSX_DEPLOYMENT_TARGET=14.5
fi

cd $WORKSPACE/srcdir/sleef

# The respective file does not exist any more on the master branch
atomic_patch -p1 ../patches/windows.patch

mkdir build-native
cd build-native
cmake \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
    -G Ninja \
    -DSLEEF_BUILD_DFT=TRUE \
    -DSLEEF_BUILD_QUAD=TRUE \
    -DSLEEF_BUILD_SCALAR_LIB=TRUE \
    -DSLEEF_BUILD_SHARED_LIBS=TRUE \
    -DSLEEF_BUILD_TESTS=OFF \
    ..
ninja all

cd $WORKSPACE/srcdir/sleef
mkdir build-cross
cd build-cross
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -G Ninja \
    -DNATIVE_BUILD_DIR=$WORKSPACE/srcdir/sleef/build-native \
    -DSLEEF_SHOW_CONFIG=1 \
    -DSLEEF_BUILD_DFT=TRUE \
    -DSLEEF_BUILD_QUAD=TRUE \
    -DSLEEF_BUILD_SCALAR_LIB=TRUE \
    -DSLEEF_BUILD_SHARED_LIBS=TRUE \
    -DSLEEF_BUILD_TESTS=OFF \
    ..
ninja all
ninja install

# Also build static (PIC) archives, so consumers can link SLEEF in directly with no
# run-time .so dependency. The motivating case is `pocl_standalone`, which ships as a
# self-contained library and cannot take a JLL dependency: it links `libsleefgnuabi.a`
# (the GNU vector-ABI / drop-in libmvec compat library) to vectorize OpenCL math builtins
# without redistributing libsleef. Install to a staging prefix and copy only the archives
# into ${prefix}, leaving the shared build's headers/CMake config/.so untouched. PIC is
# required because the archive gets linked into shared libraries. The glob just copies
# whatever archives the platform built (libsleefgnuabi.a is absent on macOS, which has no
# GNUABI variant).
cd $WORKSPACE/srcdir/sleef
mkdir build-cross-static
cd build-cross-static
cmake \
    -DCMAKE_INSTALL_PREFIX=$WORKSPACE/sleef-static \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -G Ninja \
    -DNATIVE_BUILD_DIR=$WORKSPACE/srcdir/sleef/build-native \
    -DSLEEF_SHOW_CONFIG=1 \
    -DSLEEF_BUILD_DFT=TRUE \
    -DSLEEF_BUILD_QUAD=TRUE \
    -DSLEEF_BUILD_SCALAR_LIB=TRUE \
    -DSLEEF_BUILD_SHARED_LIBS=FALSE \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DSLEEF_BUILD_TESTS=OFF \
    ..
ninja all
ninja install
cp $WORKSPACE/sleef-static/lib/*.a ${prefix}/lib/

install_license $WORKSPACE/srcdir/sleef/LICENSE.txt
"""

# Add the macOS 14.5 SDK source from the centralized helper (the script above unpacks and
# installs it non-destructively). FileSource, so it only downloads, not always unpacks.
sources = vcat(sources, get_macos_sdk_sources("14.5"))

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# 32-bit platforms are not supported any more
filter!(p -> nbits(p) > 32, platforms)
# On Windows there is a problem with exception handling. SLEEF wants
# to use sjlj, but GCC doesn't provide the respective run-time
# functions.
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsleef", :libsleef),
    LibraryProduct("libsleefdft", :libsleefdft),
    LibraryProduct("libsleefquad", :libsleefquad),
    LibraryProduct("libsleefscalar", :libsleefscalar),
]

# libsleefgnuabi -- the GNU vector-ABI / drop-in libmvec compat library, exporting the plain
# `_ZGV*` symbols LLVM emits for `-fveclib` -- is only built *and installed* by SLEEF on
# x86/AArch64/RISC-V (PPC64LE builds it but doesn't install it; macOS has no GNUABI variant),
# so declare the product only there.
gnuabi_product = LibraryProduct("libsleefgnuabi", :libsleefgnuabi)
has_gnuabi(p) = !Sys.isapple(p) && arch(p) in ("x86_64", "aarch64", "riscv64")

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD systems),
    # and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
# SLEEF uses C++20 and requires at least GCC 11.
#
# We build one platform per `build_tarballs` invocation so we can attach the
# `libsleefgnuabi` product only where it is built (everywhere except macOS); a single call
# with a platform list doesn't work here, as the ARGS-selected platform is built by every
# call regardless of the list it's passed. `--register`/`--deploy` must only be passed to
# the final invocation, so strip them from all but the last (mirrors P/pocl/build_tarballs.jl).
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)
non_reg_ARGS = filter(non_platform_ARGS) do arg
    arg != "--register" && !startswith(arg, "--deploy")
end
builds = filter(p -> should_build_platform(triplet(p)), platforms)
for (i, platform) in enumerate(builds)
    platform_products = has_gnuabi(platform) ? [products; gnuabi_product] : products
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, sources, script, [platform], platform_products, dependencies;
                   julia_compat="1.6", preferred_gcc_version=v"11")
end
