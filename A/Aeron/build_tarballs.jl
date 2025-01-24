# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Aeron"
version = v"1.47.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/real-logic/aeron.git", "066ba5518428aaadc3c4902f6cd37b8ac0864602"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
apk update && apk upgrade && apk add openjdk17 && apk del cmake

cd $WORKSPACE/srcdir/aeron

CMAKE_FLAGS=(
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
-DCMAKE_BUILD_TYPE=Release
# -DC_WARNINGS_AS_ERRORS=ON
# -DCXX_WARNINGS_AS_ERRORS=ON
-DAERON_HIDE_DEPRECATION_MESSAGE=ON
-DBUILD_AERON_DRIVER=ON
-DBUILD_AERON_ARCHIVE_API=ON
-DAERON_TESTS=OFF
-DAERON_SYSTEM_TESTS=OFF
-DAERON_BUILD_SAMPLES=OFF
-DAERON_BUILD_DOCUMENTATION=OFF
-DAERON_INSTALL_TARGETS=ON
-DCMAKE_INSTALL_PREFIX=$prefix
-DGRADLE_WRAPPER="./gradlew"
)

export GRADLE_USER_HOME=$WORKSPACE/gradle

# Apply patches
# for f in ${WORKSPACE}/srcdir/patches/*.patch; do
#     atomic_patch -p1 ${f}
# done

case "${target}" in
    *-mingw*)
        for f in ${WORKSPACE}/srcdir/patches/win32/*.patch; do
            atomic_patch -p1 ${f}
        done
        ;;
esac

cmake -B build "${CMAKE_FLAGS[@]}"
cmake --build build --parallel ${nproc} --clean-first
cmake --install build
install_license $WORKSPACE/srcdir/aeron/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libaeron", :libaeron),
    LibraryProduct("libaeron_archive_c_client", :libaeron_archive_c_client),
    LibraryProduct("libaeron_driver", :libaeron_driver),
    # Only include the statically linked version of the executable
    ExecutableProduct("aeronmd_s", :aeronmd),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Libuuid_jll"; platforms=filter(Sys.islinux, platforms)),
    HostBuildDependency(PackageSpec(; name="CMake_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"11",
)
