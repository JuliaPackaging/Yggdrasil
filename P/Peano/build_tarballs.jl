# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Peano"
version = v"21.0.0" # You can adjust this to match the LLVM fork version (e.g., 23.0.0-dev)

# Peano is the AMD/Xilinx fork of LLVM for compiling C/C++ to AIEngine processors.
sources = [
    GitSource(
        "https://github.com/Xilinx/llvm-aie.git",
        "fca3c2f87734485a529bf2eb4b1678a54ea08970", # Replace with the specific commit mlir-aie expects
    ),
]

# Build exactly what the upstream llvm-aie wheel builds, via its own CMake cache
# files (`clang/cmake/caches/Peano-AIE.cmake`, which includes the runtime-libraries
# cache). That config produces the host tools (clang/lld/llc/opt) *and* -- crucially
# -- the AIE bare-metal runtimes for each target (aie2/aie2p/aie2ps):
#
#   * compiler-rt builtins   -> lib/clang/<v>/lib/<triple>/libclang_rt.builtins.a
#   * llvm-libc + startup     -> lib/<triple>/{crt0.o,crt1.o,libc.a,libm.a}
#   * libc++ / libc++abi      -> lib/<triple>/
#
# Without these, `aiecc` cannot link a core ELF: its `clang --target=aie2p-none-unknown-elf`
# link step pulls in the builtins, crt0/crt1 and -lc/-lm, and a tools-only build
# ships none of them. The earlier recipe built only the host tools, which is why
# linking failed with "cannot open .../libclang_rt.builtins.a" and "unable to find
# library -lc". `LLVM_ENABLE_PER_TARGET_RUNTIME_DIR` (set by the cache) is what
# deposits the libc/crt under lib/<triple> where the driver looks.
script = raw"""
cd ${WORKSPACE}/srcdir/llvm-aie

# llvm-libc's header generator (libc/utils/hdrgen) runs under the build image's
# Python and imports PyYAML, which the base image lacks.
apk add py3-yaml

# The upstream cache turns on LLVM_CCACHE_BUILD as a *normal* (non-cache) variable,
# which a -D flag cannot override; the BB builder has no ccache, so drop the line.
sed -i '/LLVM_CCACHE_BUILD/d' clang/cmake/caches/Peano-AIE.cmake

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# The authoritative llvm-aie build configuration (host tools + per-target AIE
# runtimes). It sets LLVM_ENABLE_PROJECTS, the AIE experimental target,
# LLVM_ENABLE_RUNTIMES (compiler-rt;libc;libcxx;libcxxabi), the per-target
# BUILTINS_*/RUNTIMES_* options, and the distribution component list.
CMAKE_FLAGS+=(-C clang/cmake/caches/Peano-AIE.cmake)

# Reproducibility / avoid linking host libraries, matching the rest of the JLL toolchain.
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZSTD=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=FORCE_ON)

# The AIE runtimes (compiler-rt builtins, llvm-libc, libc++) must be compiled by the
# freshly built clang -- BB's gcc can't target AIE (`--target=aie2p-none-unknown-elf`).
# LLVM's own "use the just-built toolchain" path is inert here: it filters the
# toolchain tools by `if(TARGET clang)`, and clang is not yet a target when the
# runtimes register, so the runtime sub-builds neither pick up clang nor depend on it
# and just auto-detect gcc. So force the compiler for every per-target sub-build via
# the BUILTINS_*/RUNTIMES_* forwarding (which bypasses that TARGET check), pointing at
# the built clang and llvm-ar. This works because build == host -- the built clang is
# an x86_64-linux binary that runs on the builder; a host != build Peano (e.g. Windows)
# would instead need a build-native bootstrap clang here.
LLVM_BIN=${WORKSPACE}/srcdir/llvm-aie/build/bin
# The full set of tools LLVM's USE_TOOLCHAIN path would point a runtime build at
# (compiler, archiver, and the binutils replacements), so archiving/stripping AIE
# objects also goes through the LLVM tools rather than the host binutils.
TOOLS="CMAKE_C_COMPILER=clang CMAKE_CXX_COMPILER=clang++ CMAKE_ASM_COMPILER=clang \
CMAKE_AR=llvm-ar CMAKE_RANLIB=llvm-ranlib CMAKE_NM=llvm-nm CMAKE_OBJCOPY=llvm-objcopy \
CMAKE_STRIP=llvm-strip CMAKE_READELF=llvm-readelf CMAKE_OBJDUMP=llvm-objdump"
for tt in aie aie2 aie2p aie2ps; do
    t=${tt}-none-unknown-elf
    for pfx in BUILTINS RUNTIMES; do
        for kv in ${TOOLS}; do
            CMAKE_FLAGS+=(-D${pfx}_${t}_${kv%=*}=${LLVM_BIN}/${kv#*=})
        done
    done
done

# The LLVM build system expects to be run from the 'llvm' subdirectory.
cmake -B build -S llvm -GNinja ${CMAKE_FLAGS[@]}

# Build that toolchain before the runtime sub-builds run: they only depend on
# clang-resource-headers, not the tool binaries, so nothing otherwise orders them
# ahead of the sub-builds, and CMake's project() rejects a compiler path that does
# not exist yet (CMAKE_C_COMPILER_WORKS skips only the functionality test, not this).
ninja -C build -j${nproc} clang lld llvm-ar llvm-ranlib llvm-nm llvm-objcopy \
    llvm-strip llvm-readelf llvm-objdump clang-resource-headers

# `install-distribution` builds and installs just the components the cache lists:
# the host tools plus builtins-<triple>/runtimes-<triple> for aie2/aie2p/aie2ps.
ninja -C build -j${nproc} install-distribution

install_license llvm/LICENSE.TXT
"""

# x86_64 Linux only -- the RyzenAI NPU host, matching mlir_aie_jll and xrt_jll (see
# the runtimes note above on supporting a non-Linux host). Pinned to the cxx11 ABI:
# Peano ships static executables with no exported C++ ABI surface, and cxx11 is the
# only variant the wrapper and IRON consume, so building cxx03 too would just double
# an already large build.
platforms = [
    Platform("x86_64", "linux"; libc = "glibc", cxxstring_abi = "cxx11"),
]

# Extract the compiler drivers, linker, and IR optimizers.
products = [
    ExecutableProduct("clang", :clang),
    ExecutableProduct("clang++", :clangxx),
    ExecutableProduct("lld", :lld),
    ExecutableProduct("llc", :llc),
    ExecutableProduct("opt", :opt),
]

# Zlib is required by LLVM
dependencies = Dependency[
    Dependency("Zlib_jll"),
]

# LLVM needs C++17 and a modern compiler
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"10", julia_compat = "1.10"
)
