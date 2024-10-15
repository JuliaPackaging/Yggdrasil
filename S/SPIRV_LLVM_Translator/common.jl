using BinaryBuilder, Pkg

name = "SPIRV_LLVM_Translator"
repo = "https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

if llvm_version >= v"15"
    # We don't build LLVM 15 for i686-linux-musl, see
    # <https://github.com/JuliaPackaging/Yggdrasil/pull/5592#issuecomment-1430063957>:
    #     In file included from /workspace/srcdir/llvm-project/compiler-rt/lib/sanitizer_common/sanitizer_flags.h:16:0,
    #                      from /workspace/srcdir/llvm-project/compiler-rt/lib/sanitizer_common/sanitizer_common.h:18,
    #                      from /workspace/srcdir/llvm-project/compiler-rt/lib/sanitizer_common/sanitizer_platform_limits_posix.cpp:173:
    #     /workspace/srcdir/llvm-project/compiler-rt/lib/sanitizer_common/sanitizer_internal_defs.h:352:30: error: static assertion failed
    #      #define COMPILER_CHECK(pred) static_assert(pred, "")
    #                                   ^
    filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
end

# missing LLVM_full
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

# Bash recipe for building across all platforms
get_script(llvm_version) = raw"""
cd SPIRV-LLVM-Translator
install_license LICENSE.TXT

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

# Tell CMake where LLVM is
CMAKE_FLAGS+=(-DLLVM_DIR="${prefix}/lib/cmake/llvm")

# Build the library
CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)

# Use our LLVM version
CMAKE_FLAGS+=(-DBASE_LLVM_VERSION=""" * string(Base.thisminor(llvm_version)) * raw""")

# Suppress certain errors
CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-Wno-enum-constexpr-conversion")

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} llvm-spirv install
install -Dm755 build/tools/llvm-spirv/llvm-spirv${exeext} -t ${bindir}
"""

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libLLVMSPIRVLib", "LLVMSPIRVLib"], :libLLVMSPIRV),
    ExecutableProduct("llvm-spirv", :llvm_spirv),
]
