# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "SPIRV_LLVM_Translator"
version = v"23.1.1"
llvm_version = v"23.1.1+0"

# This JLL ships `libllvm_spirv`, a shared library exposing a small, typed C API
# (see bundled/libllvm_spirv.h) over a statically linked, symbol-hidden build of
# the Khronos translator (LLVM IR -> SPIR-V), replacing the `llvm-spirv`
# executable. The package version tracks the embedded LLVM's and the
# translator's release (also reported at runtime by `LLVMSPIRVGetLLVMVersion`).

# Collection of sources required to build the package
sources = [
    GitSource(
        "https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git",
        "c808623558686b7b285cabfa71542a93a5390f55"),
    DirectorySource("bundled"),
    # LLVM 22 raised its minimum macOS deployment target to 11.0, and LLVM 23's
    # headers no longer compile against the older SDK's libc++.
    get_macos_sdk_sources("11.0")...
]

# Bash recipe for building across all platforms
get_script(llvm_version) = get_macos_sdk_script("11.0") * raw"""
cd SPIRV-LLVM-Translator
atomic_patch -p1 ../phi-duplicate-predecessors.patch
install_license LICENSE.TXT

CMAKE_FLAGS=()

# glibc treats STB_GNU_UNIQUE symbols as process-unique regardless of
# visibility, which would let two LLVMs in one process share state. The flag is
# GCC-only (FreeBSD and macOS build with clang, which never emits them).
if [[ "${target}" == *-linux-* ]]; then
    CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS=-fno-gnu-unique)
fi

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
# Only the static translator library is needed; the tool is not shipped.
ninja -C build -j ${nproc} LLVMSPIRVLib

# Build libllvm_spirv: one translation unit over the static translator library
# and LLVM_full_jll's static component archives, with every LLVM and translator
# symbol hidden so only the LLVMSPIRV* API is exported. That isolation is what
# allows loading the library next to Julia's own LLVM (or a sibling back-end
# library) in one process. The API TU is compiled with exceptions so that a
# `report_fatal_error` can be turned into an error return.
cd ${WORKSPACE}/srcdir
COMMON_FLAGS=(-O2 -std=c++17 -fPIC
    -fvisibility=hidden -fvisibility-inlines-hidden -fno-rtti -fexceptions
    -ffunction-sections -fdata-sections
    -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS
    -I${prefix}/include -ISPIRV-LLVM-Translator/include)
# LLVM_full_jll's component archives; on Windows the glob would also match the
# import library of libLLVM.dll, whose symbols duplicate the archives'.
LLVM_ARCHIVES=($(ls ${prefix}/lib/libLLVM*.a | grep -v '\.dll\.a$'))
if [[ "${target}" == *-apple-* ]]; then
    # ld64 resolves across archives on its own and has no --start-group.
    LLVM_LIBS=(SPIRV-LLVM-Translator/build/lib/SPIRV/libLLVMSPIRVLib.a ${LLVM_ARCHIVES[@]})
else
    LLVM_LIBS=(-Wl,--start-group SPIRV-LLVM-Translator/build/lib/SPIRV/libLLVMSPIRVLib.a ${LLVM_ARCHIVES[@]} -Wl,--end-group)
fi
# LLVM_full_jll is built with zlib, and with zstd on some platforms.
SYSTEM_LIBS=(-L${prefix}/lib -lz)
if ls ${prefix}/lib/libzstd.* >/dev/null 2>&1; then
    SYSTEM_LIBS+=(-lzstd)
fi
# The functions declared in the header are exactly what gets exported.
API=$(sed -n 's/.*\b\(LLVMSPIRV[A-Za-z0-9]*\)(.*/\1/p' libllvm_spirv.h | sort -u)
if [[ "${target}" == *mingw* ]]; then
    # Clang/LLD like the translator build above. Export only the dllexport'd
    # API: auto-export would overflow the 64K PE export limit with the static
    # LLVM.
    LINKER=${target}-clang++
    COMMON_FLAGS+=(-pthread)
    LINK_FLAGS=(-Wl,--exclude-all-symbols -Wl,--gc-sections
        ${SYSTEM_LIBS[@]} -lole32 -luuid -lpsapi -lshell32 -ladvapi32 -lws2_32 -lntdll)
elif [[ "${target}" == *-apple-* ]]; then
    LINKER=${CXX}
    printf '_%s\n' ${API} > libllvm_spirv.exports
    LINK_FLAGS=(-Wl,-exported_symbols_list,libllvm_spirv.exports -Wl,-dead_strip
        ${SYSTEM_LIBS[@]} -lpthread -ldl -lm)
else
    LINKER=${CXX}
    if [[ "${target}" == *-linux-* ]]; then
        COMMON_FLAGS+=(-fno-gnu-unique)
    fi
    echo "{ global: $(printf '%s; ' ${API}) local: *; };" > libllvm_spirv.map
    LINK_FLAGS=(-Wl,--exclude-libs,ALL -Wl,-Bsymbolic -Wl,--gc-sections
        -Wl,--version-script=libllvm_spirv.map
        ${SYSTEM_LIBS[@]} -lpthread -lm)
    if [[ "${target}" == *-freebsd* ]]; then
        # No -z defs: `environ`, which LLVM's process support references, is
        # defined by the executable's startup code on FreeBSD, not by libc.
        LINK_FLAGS+=(-lexecinfo)
    else
        LINK_FLAGS+=(-Wl,-z,defs -ldl)
    fi
fi
mkdir -p ${libdir} ${includedir}
${LINKER} -shared -o ${libdir}/libllvm_spirv.${dlext} ${COMMON_FLAGS[@]} libllvm_spirv.cpp \
    ${LLVM_LIBS[@]} ${LINK_FLAGS[@]}
install -Dm644 libllvm_spirv.h ${includedir}/libllvm_spirv.h

# Show what got exported: only the LLVMSPIRV* API, and (on ELF) no
# STB_GNU_UNIQUE symbols, which would defeat the isolation.
if [[ "${target}" == *-linux-* || "${target}" == *-freebsd* ]]; then
    echo "exported symbols:"; nm -D --defined-only ${libdir}/libllvm_spirv.${dlext} | grep -v ' [wv] '
    echo "STB_GNU_UNIQUE symbols: $(readelf -Ws ${libdir}/libllvm_spirv.${dlext} | grep -c UNIQUE)"
elif [[ "${target}" == *-apple-* ]]; then
    echo "exported symbols:"; nm -gU ${libdir}/libllvm_spirv.${dlext}
fi
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

# The products that we will ensure are always built. `libllvm_spirv` is not
# dlopen'ed at `__init__` time: it is tens of MB, and the first `ccall` into it
# loads it on demand.
products = Product[
    LibraryProduct("libllvm_spirv", :libllvm_spirv; dont_dlopen=true),
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
    push!(builds, (; platform, sources))
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
