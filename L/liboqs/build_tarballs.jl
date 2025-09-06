using BinaryBuilder, Pkg

name = "liboqs"
version = v"0.14.0"

sources = [
    GitSource(
        "https://github.com/open-quantum-safe/liboqs.git",
        "94b421ebb82405c843dba4e9aa521a56ee5a333d",
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/liboqs
install_license LICENSE.txt

# --- Disable liboqs' intrinsics auto-detection for cross builds (BinaryBuilder) ---
# Upstream CMake probes GCC/Clang intrinsics (e.g., AVX2/AES/SSE/NEON) and, if found,
# appends flags like -mavx2/-maes. Those checks rely on try_run / host-CPU inspection.
# In a cross-compilation environment this is invalid: it can inject x86-only flags and
# trigger inclusion of <immintrin.h> even when targeting non-x86 (e.g., riscv64), which
# then fails to compile.  We replace `.CMake/gcc_clang_intrinsics.cmake` with a no-op:
#   - set OQS_INTRINSICS_FLAGS to empty, and
#   - provide detect_gcc_clang_intrinsics() that always returns "".
# This keeps the cross toolchain in control of ISA/ABI and forces portable code paths
# (in combination with -DOQS_OPT_TARGET=generic), making the build deterministic.
cat > .CMake/gcc_clang_intrinsics.cmake <<'EOF'
# BB stub: avoid try_run in cross builds
set(OQS_INTRINSICS_FLAGS "")
function(detect_gcc_clang_intrinsics outvar)
  set(${outvar} "" PARENT_SCOPE)
endfunction()
message(STATUS "BB: skipping gcc/clang intrinsics detection for cross build")
EOF

# --- Strip upstream arch-specific flags so the BB cross toolchain stays in control ---
# The upstream CMake lists per-source COMPILE_FLAGS (e.g. -mavx2, -msse2) on some files.
# In cross builds those flags can override BinaryBuilder’s --target/--sysroot and make
# non-x86 targets try to use x86-only intrinsics/headers (immintrin.h), causing failures
# (e.g. on riscv64). Remove any set_source_files_properties(... COMPILE_FLAGS ...) entries.
LC_ALL=C sed -i.bak -E '/set_source_files_properties\([^)]*COMPILE_FLAGS[^)]*\)/d' src/common/CMakeLists.txt

# The project’s helper CMake files also inject -march/-mcpu/-mtune. In cross builds these
# override the CPU/ABI chosen by the toolchain and can select unsupported ISAs or break
# assembly. The cross toolchain should be the sole source of ISA/ABI flags, so strip them.
# (Together with -DOQS_OPT_TARGET=generic this forces portable code paths across targets.)
LC_ALL=C sed -i.bak -E \
  's/-march=[^" )]+//g; s/-mcpu=[^" )]+//g; s/-mtune=[^" )]+//g' \
  .CMake/*.cmake cmake/*.cmake 2>/dev/null || true

mkdir -p build && cd build

# ---- Darwin flags (kept for completeness; no-op on Windows builds) ----
APPLE_FLAGS=()
if [[ "${target}" == *apple-darwin* ]]; then
  if [[ "${target}" == aarch64-apple-darwin* ]]; then DARWIN_CPU=arm64; else DARWIN_CPU=x86_64; fi
  APPLE_FLAGS+=(
    -DCMAKE_SYSTEM_NAME=Darwin
    -DCMAKE_SYSTEM_VERSION=20
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0
    -DCMAKE_SHARED_LIBRARY_SUFFIX=.dylib
    -DCMAKE_SYSTEM_PROCESSOR=${DARWIN_CPU}
    -DCMAKE_OSX_ARCHITECTURES=${DARWIN_CPU}
    -DCMAKE_INSTALL_NAME_DIR=@rpath
    -DCMAKE_INSTALL_RPATH=@rpath
    -DOQS_PERMIT_UNSUPPORTED_ARCHITECTURE=ON
  )
  export MACOSX_DEPLOYMENT_TARGET=11.0
fi

# ---- Use clang/lld on Linux/BSD/Windows targets ----
EXTRA_FLAGS=()
if [[ "${target}" == *-linux-* || "${target}" == *-freebsd* || "${target}" == *-w64-mingw32 ]]; then
  SYSROOT="/opt/${target}/${target}/sys-root"
  EXTRA_FLAGS+=(
    -DCMAKE_C_COMPILER=clang
    -DCMAKE_C_COMPILER_TARGET=${target}
    -DCMAKE_SYSROOT=${SYSROOT}
    -DCMAKE_AR=$(command -v llvm-ar)
    -DCMAKE_RANLIB=$(command -v llvm-ranlib)
    -DCMAKE_NM=$(command -v llvm-nm)
  )

  # ---- extra for MinGW ----
  if [[ "${target}" == *-w64-mingw32 ]]; then
    [[ -x "$(command -v llvm-rc)" ]] && EXTRA_FLAGS+=(-DCMAKE_RC_COMPILER=$(command -v llvm-rc))
    EXTRA_FLAGS+=(
      -DCMAKE_SYSTEM_NAME=Windows
      -DCMAKE_SYSTEM_VERSION=10
      -DOQS_PERMIT_UNSUPPORTED_ARCHITECTURE=ON
    )
  fi

  if command -v ld.lld >/dev/null 2>&1; then
    export LD=$(command -v ld.lld)
    export LDFLAGS="-fuse-ld=lld ${LDFLAGS}"
    EXTRA_FLAGS+=(
      -DCMAKE_LINKER=${LD}
      -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS}"
      -DCMAKE_SHARED_LINKER_FLAGS="${LDFLAGS}"
      -DCMAKE_MODULE_LINKER_FLAGS="${LDFLAGS}"
    )
  fi

  export CC=clang
  export AR=$(command -v llvm-ar)
  export RANLIB=$(command -v llvm-ranlib)
  export NM=$(command -v llvm-nm)
  export CFLAGS="--target=${target} --sysroot=${SYSROOT} ${CFLAGS}"
  export ASFLAGS="--target=${target} --sysroot=${SYSROOT} ${ASFLAGS}"
  # Disable GOTPCRELX relaxation on x86/x86_64 to allow linking with older bfd ld
  if [[ "${target}" == x86_64-* || "${target}" == i686-* ]]; then
    export CFLAGS="${CFLAGS} -Wa,-mrelax-relocations=no"
    export CXXFLAGS="${CXXFLAGS} -Wa,-mrelax-relocations=no"
    # Also apply to plain assembly
    export ASFLAGS="${ASFLAGS} -mrelax-relocations=no"
  fi
fi
# ----------------------------

# We disable OpenSSL to avoid MinGW resolution issues
cmake -S .. -B . -G Ninja \
  -DBUILD_SHARED_LIBS=ON \
  -DOQS_BUILD_ONLY_LIB=ON \
  -DOQS_USE_OPENSSL=OFF \
  -DOQS_DIST_BUILD=OFF \
  -DOQS_OPT_TARGET=generic \
  -DCMAKE_INSTALL_PREFIX="${prefix}" \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_C_FLAGS="${CFLAGS}" \
  -DCMAKE_ASM_FLAGS="${ASFLAGS}" \
  -DCMAKE_BUILD_TYPE=Release \
  "${APPLE_FLAGS[@]}" \
  "${EXTRA_FLAGS[@]}"

ninja
ninja install
"""

products = [LibraryProduct("liboqs", :liboqs)]

platforms = [
    # glibc Linuces
    Platform("i686", "linux"), # OK
    Platform("x86_64", "linux"), # OK
    Platform("aarch64", "linux"), # OK
    Platform("armv6l", "linux"), # OK
    Platform("armv7l", "linux"), # OK
    # Platform("powerpc64le", "linux"), # Builds fail on this platform.
    # Platform("riscv64", "linux"), # Builds fail on this platform.

    # musl Linuces
    Platform("i686", "linux"; libc = "musl"), # OK
    Platform("x86_64", "linux"; libc = "musl"), # OK
    Platform("aarch64", "linux"; libc = "musl"), # OK
    Platform("armv6l", "linux"; libc = "musl"), # OK
    Platform("armv7l", "linux"; libc = "musl"), # OK

    # BSDs
    Platform("x86_64", "macos"), # OK
    Platform("aarch64", "macos"), # OK
    Platform("x86_64", "freebsd"), # OK
    Platform("aarch64", "freebsd"), # OK

    # Windows
    Platform("i686", "windows"), # OK
    Platform("x86_64", "windows"), # OK
]

dependencies = [
    HostBuildDependency(
        PackageSpec(name = "Ninja_jll", uuid = "76642167-d241-5cee-8c94-7a494e8cb7b7"),
    ),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.10",
)
