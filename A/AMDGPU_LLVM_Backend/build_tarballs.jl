# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AMDGPU_LLVM_Backend"
version = v"23.1.1"
llvm_version = v"23.1.1"

# This JLL ships `libamdgpu`, a shared library exposing a small, typed C API (see
# bundled/libamdgpu.h) over a statically linked, symbol-hidden LLVM AMDGPU
# back-end and lld, replacing the `llc` and `lld` executables, plus the ROCm
# device libraries as bitcode. The package version tracks the embedded LLVM's
# (also reported at runtime by `AMDGPUGetLLVMVersion`).
#
# Collection of sources required to build AMDGPU_LLVM_Backend.
# LLVM ships a single monorepo source archive (`llvm-project-X.Y.Z.src.tar.xz`).
sources = [
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(llvm_version)/llvm-project-$(llvm_version).src.tar.xz",
                  "ebe9be46fe8756d58c5b198ffad0fa2a766257add81a4dc52179bfacc7888ee6"),
    GitSource("https://github.com/ROCm/llvm-project",
              "46fcb339fb61119b337f973c7ca9e710a319fdd0"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
# Apply backported patches to the upstream LLVM sources.
# LLVM installs process-wide signal handlers (and, on Windows, an unhandled-
# exception filter) when it registers files to remove on crash, e.g. for lld's
# output file, and when a CrashRecoveryContext is enabled. Embedded in Julia,
# which synchronises its threads with SIGSEGV, those handlers are fatal: they
# intercept the host's signals and re-raise them with a different siginfo.
# Make every such installation a no-op; the library never wants them.
pushd llvm-project-*
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
popd

cd llvm-project-*/llvm
LLVM_SRCDIR=$(pwd)

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

# Tell CMake to enable lld in the target build
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS=lld)

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
else
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
    # glibc treats STB_GNU_UNIQUE symbols as process-unique regardless of
    # visibility, which would let two LLVMs in one process share state.
    CXX_FLAGS="-fno-gnu-unique"
fi
CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="${CXX_FLAGS}")
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Only build the AMDGPU back-end
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD=AMDGPU)

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
# Building `llc` and `lld` builds exactly the component archives the library
# needs; the executables themselves are not shipped.
ninja -j${nproc} llc lld

# Build libamdgpu: one translation unit over the static LLVM and lld component
# archives, with every LLVM symbol hidden so only the AMDGPU* API is exported.
# That isolation is what allows loading the library next to Julia's own LLVM
# (or a sibling back-end library) in one process. The API TU is compiled with
# exceptions so that a `report_fatal_error` can be turned into an error return.
cd ${WORKSPACE}/srcdir
COMMON_FLAGS=(-O2 -std=c++17 -fPIC
    -fvisibility=hidden -fvisibility-inlines-hidden -fno-rtti -fexceptions
    -ffunction-sections -fdata-sections
    -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS
    -I${LLVM_SRCDIR}/include -I${WORKSPACE}/build/include
    -I${LLVM_SRCDIR}/../lld/include)
LLVM_LIBS=(-Wl,--start-group ${WORKSPACE}/build/lib/libLLVM*.a ${WORKSPACE}/build/lib/liblld*.a -Wl,--end-group)
if [[ "${target}" == *mingw* ]]; then
    # Clang/LLD, see above. Export only the dllexport'd API: auto-export would
    # overflow the 64K PE export limit with the static LLVM.
    LINKER=${target}-clang++
    COMMON_FLAGS+=(-pthread)
    LINK_FLAGS=(-Wl,--exclude-all-symbols -Wl,--gc-sections
        -L${prefix}/lib -lz -lole32 -luuid -lpsapi -lshell32 -ladvapi32 -lws2_32 -lntdll)
else
    LINKER=${CXX}
    COMMON_FLAGS+=(-fno-gnu-unique)
    # Export exactly the functions declared in the header.
    API=$(sed -n 's/.*\b\(AMDGPU[A-Za-z0-9]*\)(.*/\1/p' libamdgpu.h | sort -u)
    echo "{ global: $(printf '%s; ' ${API}) local: *; };" > libamdgpu.map
    LINK_FLAGS=(-Wl,--exclude-libs,ALL -Wl,-Bsymbolic -Wl,--gc-sections -Wl,-z,defs
        -Wl,--version-script=libamdgpu.map
        -L${prefix}/lib -lz -lpthread -ldl -lm)
fi
mkdir -p ${libdir} ${includedir}
${LINKER} -shared -o ${libdir}/libamdgpu.${dlext} ${COMMON_FLAGS[@]} libamdgpu.cpp \
    ${LLVM_LIBS[@]} ${LINK_FLAGS[@]}
install -Dm644 libamdgpu.h ${includedir}/libamdgpu.h

# Show what got exported: only the AMDGPU* API, and (on ELF) no STB_GNU_UNIQUE
# symbols, which would defeat the isolation.
if [[ "${target}" == *linux* ]]; then
    echo "exported symbols:"; nm -D --defined-only ${libdir}/libamdgpu.${dlext} | grep -v ' [wv] '
    echo "STB_GNU_UNIQUE symbols: $(readelf -Ws ${libdir}/libamdgpu.${dlext} | grep -c UNIQUE)"
fi

# build device libs, those live in the ROCm llvm fork
# `ockl/src/workitem.cl` includes `amdhsa_abi.h`, which LLVM_full_jll's Clang doesn't have so just copy it
cp ${WORKSPACE}/srcdir/llvm-project/clang/lib/Headers/amdhsa_abi.h \
   ${WORKSPACE}/srcdir/llvm-project/amd/device-libs/ockl/inc/
mkdir ${WORKSPACE}/build-device-libs && cd ${WORKSPACE}/build-device-libs
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
# `prepare-builtins` must run during the build, so build it with the host toolchain
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})
# Locate the host LLVM/Clang cmake packages from LLVM_full_jll
CMAKE_FLAGS+=(-DCMAKE_PREFIX_PATH=${host_prefix})
cmake -GNinja ${WORKSPACE}/srcdir/llvm-project/amd/device-libs ${CMAKE_FLAGS[@]}
ninja -j${nproc} install

# combine the upstream LLVM and device libs licenses
cat ${LLVM_SRCDIR}/LICENSE.TXT ${WORKSPACE}/srcdir/llvm-project/amd/device-libs/LICENSE.TXT > LICENSE.TXT
install_license LICENSE.TXT
"""

# Only build for the host platforms where AMDGPU itself runs.
platforms = [
    Platform("x86_64",  "linux";   libc="glibc"),
    Platform("aarch64", "linux";   libc="glibc"),
    Platform("x86_64",  "windows"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
# `libamdgpu` is not dlopen'ed at `__init__` time: it is tens of MB, and the
# first `ccall` into it loads it on demand.
products = Product[
    LibraryProduct("libamdgpu", :libamdgpu; dont_dlopen=true),
    FileProduct("amdgcn/bitcode/", :bitcode_path),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll")
    # Host LLVM+Clang toolchain for compiling the device libraries to bitcode.
    # It may trail the LLVM built here: its bitcode is auto-upgraded on load.
    HostBuildDependency(PackageSpec(; name="LLVM_full_jll", version=v"22.1.8+0"))
]

build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6")

# bump
