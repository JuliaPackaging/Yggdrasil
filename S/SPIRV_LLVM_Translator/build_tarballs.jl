# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "SPIRV_LLVM_Translator"
version = v"21.1.1"
llvm_version = v"21.1.2"

# Collection of sources required to build the package
sources = [
    GitSource(
        "https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git",
        "29758b55816c14abb3e4142d42aca7a95bf46710"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
get_script(llvm_version) = raw"""
cd SPIRV-LLVM-Translator
atomic_patch -p1 ../addrspacecast_null.patch
install_license LICENSE.TXT

if [[ ("${target}" == x86_64-apple-darwin*) ]]; then
    # LLVM 15+ requires macOS SDK 10.14
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
if [[ "${target}" == *mingw* ]]; then
    # on Windows, we run into "multiple definition" errors when linking with gcc
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake)
else
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
fi
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

# More hacks for Windows
if [[ "${target}" == *mingw* ]]; then
    CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS=\"-pthread\")
fi

# Tell CMake where LLVM is
CMAKE_FLAGS+=(-DLLVM_DIR="${prefix}/lib/cmake/llvm")

# Don't link dynamically against libLLVM, but statically against each component
#CMAKE_FLAGS+=(-DLLVM_LINK_LLVM_DYLIB=OFF)
# XXX: doesn't seem to work, so patch the CMakeLists.txt instead
sed -i '/add_llvm_library(/a DISABLE_LLVM_LINK_LLVM_DYLIB' lib/SPIRV/CMakeLists.txt
sed -i '/add_llvm_tool(/a DISABLE_LLVM_LINK_LLVM_DYLIB' tools/llvm-spirv/CMakeLists.txt

# Use our LLVM version
CMAKE_FLAGS+=(-DBASE_LLVM_VERSION=""" * string(Base.thisminor(llvm_version)) * raw""")

if [[ "${target}" == *-apple-darwin* ]]; then
    cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]} -DCMAKE_CXX_FLAGS="-Wno-error=enum-constexpr-conversion -include vector"
else
    cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
fi
ninja -C build -j ${nproc} llvm-spirv install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# We don't build LLVM 15+ for i686-linux-musl, see
# <https://github.com/JuliaPackaging/Yggdrasil/pull/5592#issuecomment-1430063957>:
#     In file included from /workspace/srcdir/llvm-project/compiler-rt/lib/sanitizer_common/sanitizer_flags.h:16:0,
#                      from /workspace/srcdir/llvm-project/compiler-rt/lib/sanitizer_common/sanitizer_common.h:18,
#                      from /workspace/srcdir/llvm-project/compiler-rt/lib/sanitizer_common/sanitizer_platform_limits_posix.cpp:173:
#     /workspace/srcdir/llvm-project/compiler-rt/lib/sanitizer_common/sanitizer_internal_defs.h:352:30: error: static assertion failed
#      #define COMPILER_CHECK(pred) static_assert(pred, "")
#                                   ^
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("llvm-spirv", :llvm_spirv)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
    Dependency("Zstd_jll"), # our LLVM 20 build has LLVM_ENABLE_ZSTD=ON
]

# Determine the builds
builds = []
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    # On macOS, we need to use a newer SDK to match the one LLVM was built with
    platform_sources = if Sys.isapple(platform) && arch(platform) == "x86_64"
        [sources;
         ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                       "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f")]
    else
        sources
    end

    push!(builds, (; platform, sources=platform_sources))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` and `--deploy` should only be passed to the final `build_tarballs` invocation
non_reg_ARGS = filter(non_platform_ARGS) do arg
    arg != "--register" && !startswith(arg, "--deploy")
end

# Build the tarballs.
for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, get_script(llvm_version), [build.platform],
                   products, dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
end
