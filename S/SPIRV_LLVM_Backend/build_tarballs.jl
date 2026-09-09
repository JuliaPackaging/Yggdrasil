# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "SPIRV_LLVM_Backend"
version = v"23.1.1"
llvm_version = v"23.1.1"

# This JLL ships `libspirv`, a shared library exposing a small, typed C API (see
# bundled/libspirv.h) over a statically linked, symbol-hidden LLVM SPIR-V
# back-end, replacing the `llc` executable. The package version tracks the
# embedded LLVM's (also reported at runtime by `SPIRVGetLLVMVersion`).
#
# Collection of sources required to build SPIRV_LLVM_Backend.
# LLVM ships a single monorepo source archive (`llvm-project-X.Y.Z.src.tar.xz`).
sources = [
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(llvm_version)/llvm-project-$(llvm_version).src.tar.xz",
                  "ebe9be46fe8756d58c5b198ffad0fa2a766257add81a4dc52179bfacc7888ee6"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mv llvm-project-* llvm-project

cd llvm-project/llvm
LLVM_SRCDIR=$(pwd)

# Workaround for building with an old macOS SDK that lacks a working
# __builtin_available (still applicable on LLVM 23).
# LLVM installs process-wide signal handlers (and, on Windows, an unhandled-
# exception filter) when it registers files to remove on crash, e.g. for lld's
# output file, and when a CrashRecoveryContext is enabled. Embedded in Julia,
# which synchronises its threads with SIGSEGV, those handlers are fatal: they
# intercept the host's signals and re-raise them with a different siginfo.
# Make every such installation a no-op; the library never wants them.
atomic_patch -p1 $WORKSPACE/srcdir/patches/no-process-wide-handlers.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/avoid_builtin_available.patch
# Backport of https://github.com/llvm/llvm-project/pull/204231 ("[SPIRV]
# Legalize i1 min/max before selection"; merged after the 23.x branch).
atomic_patch -p1 $WORKSPACE/srcdir/patches/minmax_i1.patch
# Backport of https://github.com/llvm/llvm-project/pull/204239 ("[SPIR-V] Lower
# nested aggregate insertvalue operands"; merged after the 23.x branch).
atomic_patch -p1 $WORKSPACE/srcdir/patches/nested_aggregate_insertvalue.patch
# Fix direct returns of aggregate extractvalue results, such as the LLVM IR
# emitted for non-inlined SMatrix{1,1} returns.
atomic_patch -p1 $WORKSPACE/srcdir/patches/aggregate_extractvalue_return.patch

install_license LICENSE.TXT

# The very first thing we need to do is to build llvm-tblgen for x86_64-linux-muslc
# This is because LLVM's cross-compile setup is kind of borked, so we just
# build the tools natively ourselves, directly.  :/

# Build llvm-tblgen and llvm-config
mkdir ${WORKSPACE}/bootstrap
pushd ${WORKSPACE}/bootstrap
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=host)
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm')
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=False)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})
cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} llvm-tblgen llvm-config
popd

# Let's do the actual build within the `build` subdirectory
mkdir ${WORKSPACE}/build && cd ${WORKSPACE}/build
CMAKE_FLAGS=()

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling.
# On Windows, build with the Clang/LLD toolchain: the library below is linked
# with lld (GNU ld is pathologically slow producing a DLL out of large static
# LLVM archives), and mixing GCC-built archives into a Clang/LLD link is not a
# combination we want to debug.
if [[ "${target}" == *mingw* ]]; then
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake)
    CXX_FLAGS="-pthread"
elif [[ "${target}" == *-linux-* ]]; then
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
    # glibc treats STB_GNU_UNIQUE symbols as process-unique regardless of
    # visibility, which would let two LLVMs in one process share state. The
    # flag is GCC-only (FreeBSD and macOS build with clang, which never emits
    # such symbols).
    CXX_FLAGS="-fno-gnu-unique"
else
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
    CXX_FLAGS=""
fi
CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="${CXX_FLAGS}")
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Only build the SPIR-V back-end
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD=SPIRV)

# Turn on ZLIB
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=ON)
# Turn off XML2 and ZSTD to avoid unnecessary dependencies
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZSTD=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

# Disable useless things like docs, terminfo, etc....
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=Off)
CMAKE_FLAGS+=(-DLLVM_ENABLE_TERMINFO=Off)
CMAKE_FLAGS+=(-DHAVE_HISTEDIT_H=Off)
CMAKE_FLAGS+=(-DHAVE_LIBEDIT=Off)

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
# Building `llc` builds exactly the component archives the library needs; the
# executable itself is not shipped.
ninja -j${nproc} llc

# Build libspirv: one translation unit over the static component archives, with
# every LLVM symbol hidden so only the SPIRV* API is exported. That isolation is
# what allows loading the library next to Julia's own LLVM (or a sibling
# back-end library) in one process. The API TU is compiled with exceptions so
# that a `report_fatal_error` can be turned into an error return. It uses the
# back-end's private headers (extension handling), hence the in-tree includes.
cd ${WORKSPACE}/srcdir
COMMON_FLAGS=(-O2 -std=c++17 -fPIC
    -fvisibility=hidden -fvisibility-inlines-hidden -fno-rtti -fexceptions
    -ffunction-sections -fdata-sections
    -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS
    -I${LLVM_SRCDIR}/include -I${WORKSPACE}/build/include
    -I${LLVM_SRCDIR}/lib/Target/SPIRV -I${WORKSPACE}/build/lib/Target/SPIRV)
if [[ "${target}" == *-apple-* ]]; then
    # ld64 resolves across archives on its own and has no --start-group.
    LLVM_LIBS=(${WORKSPACE}/build/lib/libLLVM*.a)
else
    LLVM_LIBS=(-Wl,--start-group ${WORKSPACE}/build/lib/libLLVM*.a -Wl,--end-group)
fi
# The functions declared in the header are exactly what gets exported.
API=$(sed -n 's/.*\b\(SPIRV[A-Za-z0-9]*\)(.*/\1/p' libspirv.h | sort -u)
if [[ "${target}" == *mingw* ]]; then
    # Clang/LLD, see above. Export only the dllexport'd API: auto-export would
    # overflow the 64K PE export limit with the static LLVM.
    LINKER=${target}-clang++
    COMMON_FLAGS+=(-pthread)
    LINK_FLAGS=(-Wl,--exclude-all-symbols -Wl,--gc-sections
        -L${prefix}/lib -lz -lole32 -luuid -lpsapi -lshell32 -ladvapi32 -lws2_32 -lntdll)
elif [[ "${target}" == *-apple-* ]]; then
    LINKER=${CXX}
    printf '_%s\n' ${API} > libspirv.exports
    LINK_FLAGS=(-Wl,-exported_symbols_list,libspirv.exports -Wl,-dead_strip
        -L${prefix}/lib -lz -lpthread -ldl -lm)
else
    LINKER=${CXX}
    if [[ "${target}" == *-linux-* ]]; then
        COMMON_FLAGS+=(-fno-gnu-unique)
    fi
    echo "{ global: $(printf '%s; ' ${API}) local: *; };" > libspirv.map
    LINK_FLAGS=(-Wl,--exclude-libs,ALL -Wl,-Bsymbolic -Wl,--gc-sections
        -Wl,--version-script=libspirv.map
        -L${prefix}/lib -lz -lpthread -lm)
    if [[ "${target}" == *-freebsd* ]]; then
        # No -z defs: `environ`, which LLVM's process support references, is
        # defined by the executable's startup code on FreeBSD, not by libc.
        LINK_FLAGS+=(-lexecinfo)
    else
        LINK_FLAGS+=(-Wl,-z,defs -ldl)
    fi
fi
mkdir -p ${libdir} ${includedir}
${LINKER} -shared -o ${libdir}/libspirv.${dlext} ${COMMON_FLAGS[@]} libspirv.cpp \
    ${LLVM_LIBS[@]} ${LINK_FLAGS[@]}
install -Dm644 libspirv.h ${includedir}/libspirv.h

# Show what got exported: only the SPIRV* API, and (on ELF) no STB_GNU_UNIQUE
# symbols, which would defeat the isolation.
if [[ "${target}" == *-linux-* || "${target}" == *-freebsd* ]]; then
    echo "exported symbols:"; nm -D --defined-only ${libdir}/libspirv.${dlext} | grep -v ' [wv] '
    echo "STB_GNU_UNIQUE symbols: $(readelf -Ws ${libdir}/libspirv.${dlext} | grep -c UNIQUE)"
elif [[ "${target}" == *-apple-* ]]; then
    echo "exported symbols:"; nm -gU ${libdir}/libspirv.${dlext}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
# `libspirv` is not dlopen'ed at `__init__` time: it is tens of MB, and the first
# `ccall` into it loads it on demand.
products = Product[
    LibraryProduct("libspirv", :libspirv; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll")
]

# LLVM 22 raised its minimum macOS deployment target to 11.0, and LLVM 23's
# headers no longer compile against the older SDK's libc++. The helper only
# redirects x86_64-apple-darwin; aarch64-apple-darwin already uses an 11.1 SDK.
sources, script = require_macos_sdk("11.0", sources, script)

build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6")
