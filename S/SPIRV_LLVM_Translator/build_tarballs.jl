# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SPIRV_LLVM_Translator"
version = v"19.1"
llvm_version = v"19.1.7"

# Collection of sources required to build the package
sources = [
    GitSource(
        "https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git",
        "5e73fab9bf001890789f97fd389fe7e50f4aefba"),
    ArchiveSource(
        "https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
        "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f")
]

# Bash recipe for building across all platforms
get_script(llvm_version) = raw"""
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

if [[ "${target}" == i686-w64-mingw32 ]]; then
    # Work around https://gcc.gnu.org/bugzilla/show_bug.cgi?id=116159
    # Should be fixed with GCC 14.3
    sed -i '/_ZSt21ios_base_library_initv/s/.*/#define XSTRINGIFY(X) STRINGIFY(X)\n#define STRINGIFY(X) #X\n__extension__ __asm (".globl " XSTRINGIFY(__USER_LABEL_PREFIX__) "_ZSt21ios_base_library_initv");/' /opt/i686-w64-mingw32/i686-w64-mingw32/include/c++/13.2.0/iostream
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

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} llvm-spirv install
install -Dm755 build/tools/llvm-spirv/llvm-spirv${exeext} -t ${bindir}
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
    LibraryProduct(["libLLVMSPIRVLib", "LLVMSPIRVLib"], :libLLVMSPIRV),
    ExecutableProduct("llvm-spirv", :llvm_spirv),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, get_script(llvm_version), platforms, products,
               dependencies; preferred_gcc_version=v"13", julia_compat="1.6")
