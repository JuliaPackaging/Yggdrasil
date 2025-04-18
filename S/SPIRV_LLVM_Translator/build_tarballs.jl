# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "SPIRV_LLVM_Translator"
version = v"20.1"
llvm_version = v"20.1.2"

# Collection of sources required to build the package
sources = [
    GitSource(
        "https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git",
        "dee371987a59ed8654083c09c5f1d5c54f5db318")
]

# Bash recipe for building across all platforms
script = raw"""
cd SPIRV-LLVM-Translator
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
    CMAKE_FLAGS+=(-DCMAKE_SHARED_LIBRARY_CXX_FLAGS=\"-pthread\")
fi

# Tell CMake where LLVM is
CMAKE_FLAGS+=(-DLLVM_DIR="${prefix}/lib/cmake/llvm")

# Build the library
CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)

# Don't link dynamically against libLLVM, but statically against each component
#CMAKE_FLAGS+=(-DLLVM_LINK_LLVM_DYLIB=OFF)
# XXX: doesn't seem to work, so patch the CMakeLists.txt instead
sed -i '/add_llvm_library(/a DISABLE_LLVM_LINK_LLVM_DYLIB' lib/SPIRV/CMakeLists.txt
sed -i '/add_llvm_tool(/a DISABLE_LLVM_LINK_LLVM_DYLIB' tools/llvm-spirv/CMakeLists.txt
# XXX: linking both libLLVM (statically) and libLLVMSPIRVLib (dynamically) breaks things
sed -i '/add_llvm_tool(/i set(LLVM_LINK_COMPONENTS "")' tools/llvm-spirv/CMakeLists.txt

# Use our LLVM version
CMAKE_FLAGS+=(-DBASE_LLVM_VERSION=""" * string(Base.thisminor(llvm_version)) * raw""")

# Suppress certain errors
CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-Wno-enum-constexpr-conversion")

# Enable support for SPIR-V Tools-assisted disassembly
CMAKE_FLAGS+=(-DLLVM_SPIRV_ENABLE_LIBSPIRV_DIS:BOOL=ON)

# Point to the SPIR-V headers
CMAKE_FLAGS+=(-DLLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR=${includedir})

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} llvm-spirv install
install -Dm755 build/tools/llvm-spirv/llvm-spirv${exeext} -t ${bindir}

# Remove unwanted static libraries
rm -f $prefix/lib/libLLVMSPIRVLib*.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
## We don't build LLVM 15+ for i686-linux-musl
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libLLVMSPIRVLib", "LLVMSPIRVLib"], :libLLVMSPIRV),
    ExecutableProduct("llvm-spirv", :llvm_spirv),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("SPIRV_Tools_jll"),
    BuildDependency("SPIRV_Headers_jll"),
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
]

builds = []
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    # On macOS, we need to use a newer SDK which supports `std::filesystem`
    platform_sources = if Sys.isapple(platform)
        [sources;
         ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                       "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f")]
    else
        sources
    end

    # on Windows, we need to use a version of GCC that supports `.drectve -exclude-symbols`
    preferred_gcc_version = if Sys.iswindows(platform)
        v"13"
    else
        v"10"
    end

    push!(builds, (; platform, sources=platform_sources, preferred_gcc_version))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script, [build.platform], products,
                   dependencies; build.preferred_gcc_version, julia_compat="1.6")
end
