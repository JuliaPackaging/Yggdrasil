
set(PACKAGE_VENDOR Yggdrasil CACHE STRING "")

# We build for all platforms of interest to us.
set(LLVM_TARGETS_TO_BUILD X86;ARM;AArch64;PowerPC CACHE STRING "")

set(LLVM_ENABLE_PROJECTS "clang;lld;llvm" CACHE STRING "")
set(LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING "")

set(LLVM_BINDINGS_LIST "" CACHE STRING "")

# Enable shared library build
# TODO: Since we are bootstrapping we don't really need this.
# set(LLVM_BUILD_LLVM_DYLIB ON CACHE BOOL "")
# set(LLVM_LINK_LLVM_DYLIB ON CACHE BOOL "")

# Turn off docs
set(LLVM_INCLUDE_DOCS OFF CACHE BOOL "")
set(LLVM_INCLUDE_EXAMPLES OFF CACHE BOOL "")

set(LLVM_ENABLE_PER_TARGET_RUNTIME_DIR ON CACHE BOOL "")
set(LLVM_ENABLE_CXX1Y ON CACHE BOOL "")
set(LLVM_ENABLE_PIC ON CACHE BOOL "")

# Clang settings
set(CLANG_DEFAULT_CXX_STDLIB libc++ CACHE STRING "")
set(CLANG_DEFAULT_LINKER lld CACHE STRING "")
set(CLANG_DEFAULT_OBJCOPY llvm-objcopy CACHE STRING "")
set(CLANG_DEFAULT_RTLIB compiler-rt CACHE STRING "")

# LIBCXXABI settings
set(LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")

# LIBCXX settings
set(LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")

# Compiler-rt settings
# Sanitizers don't support musl
# https://reviews.llvm.org/D63785


# Setup builtins/runtimes build
# Tell compiler-rt to generate builtins for all the supported arches
set(COMPILER_RT_DEFAULT_TARGET_ONLY OFF CACHE BOOL "")
set(RUNTIMES_BUILD_ALLOW_DARWIN ON CACHE BOOL "")
set(ENABLE_LINKER_BUILD_ID ON CACHE BOOL "")

function(CONFIGURE target is_musl OS SYSTEM build_sanitizers build_runtime)
  # Set the per-target builtins options.
  list(APPEND BUILTIN_TARGETS "${target}")
  set(BUILTIN_TARGETS ${BUILTIN_TARGETS} PARENT_SCOPE)

  set(BUILTINS_${target}_CMAKE_BUILD_TYPE Release CACHE STRING "")
  set(BUILTINS_${target}_LLVM_ENABLE_CXX1Y ON CACHE BOOL "")
  set(BUILTINS_${target}_CMAKE_SYSTEM_NAME "${OS}" CACHE STRING "")
  set(BUILTINS_${target}_CMAKE_C_FLAGS "--target=${target}" CACHE STRING "")
  set(BUILTINS_${target}_CMAKE_CXX_FLAGS "--target=${target}" CACHE STRING "")
  set(BUILTINS_${target}_CMAKE_ASM_FLAGS "--target=${target}" CACHE STRING "")
  set(BUILTINS_${target}_CMAKE_SYSROOT "/opt/${SYSTEM}/${SYSTEM}/sys-root" CACHE STRING "")
  set(BUILTINS_${target}_CMAKE_SHARED_LINKER_FLAGS "-fuse-ld=lld" CACHE STRING "")
  set(BUILTINS_${target}_CMAKE_MODULE_LINKER_FLAGS "-fuse-ld=lld" CACHE STRING "")
  set(BUILTINS_${target}_CMAKE_EXE_LINKER_FLAGS "-fuse-ld=lld" CACHE STRING "")

  # Set the per-target runtimes options.
  if(build_runtime)
    list(APPEND RUNTIME_TARGETS "${target}")
    set(RUNTIME_TARGETS ${RUNTIME_TARGETS} PARENT_SCOPE)
  endif()

  set(RUNTIMES_${target}_CMAKE_BUILD_TYPE Release CACHE STRING "")
  set(RUNTIMES_${target}_LLVM_ENABLE_CXX1Y ON CACHE BOOL "")
  set(RUNTIMES_${target}_CMAKE_SYSTEM_NAME "${OS}" CACHE STRING "")

  set(RUNTIMES_${target}_CMAKE_C_FLAGS "--target=${target} --gcc-toolchain=/opt/${SYSTEM}" CACHE STRING "")
  set(RUNTIMES_${target}_CMAKE_CXX_FLAGS "--target=${target} --gcc-toolchain=/opt/${SYSTEM}" CACHE STRING "")
  set(RUNTIMES_${target}_CMAKE_ASM_FLAGS "--target=${target} --gcc-toolchain=/opt/${SYSTEM}" CACHE STRING "")
  # set(RUNTIMES_${target}_CMAKE_C_FLAGS "--target=${target}" CACHE STRING "")
  # set(RUNTIMES_${target}_CMAKE_CXX_FLAGS "--target=${target}" CACHE STRING "")
  # set(RUNTIMES_${target}_CMAKE_ASM_FLAGS "--target=${target}" CACHE STRING "")
  set(RUNTIMES_${target}_CMAKE_SYSROOT "/opt/${SYSTEM}/${SYSTEM}/sys-root" CACHE STRING "")
  set(RUNTIMES_${target}_CMAKE_SHARED_LINKER_FLAGS "-fuse-ld=lld -L/opt/${SYSTEM}/${SYSTEM}/lib" CACHE STRING "")
  set(RUNTIMES_${target}_CMAKE_MODULE_LINKER_FLAGS "-fuse-ld=lld -L/opt/${SYSTEM}/${SYSTEM}/lib" CACHE STRING "")
  set(RUNTIMES_${target}_CMAKE_EXE_LINKER_FLAGS "-fuse-ld=lld -L/opt/${SYSTEM}/${SYSTEM}/lib" CACHE STRING "")
  # set(RUNTIMES_${target}_CMAKE_SHARED_LINKER_FLAGS "-fuse-ld=lld" CACHE STRING "")
  # set(RUNTIMES_${target}_CMAKE_MODULE_LINKER_FLAGS "-fuse-ld=lld " CACHE STRING "")
  # set(RUNTIMES_${target}_CMAKE_EXE_LINKER_FLAGS "-fuse-ld=lld" CACHE STRING "")
  set(RUNTIMES_${target}_LIBCXXABI_GCC_TOOLCHAIN "/opt/${SYSTEM}" ON CACHE STRING "")
  set(RUNTIMES_${target}_LIBCXX_GCC_TOOLCHAIN "/opt/${SYSTEM}" ON CACHE STRING "")
  set(RUNTIMES_${target}_LIBUNWIND_GCC_TOOLCHAIN "/opt/{SYSTEM}" ON CACHE STRING "")
  set(RUNTIMES_${target}_COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")
  set(RUNTIMES_${target}_LIBUNWIND_ENABLE_SHARED OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")
  set(RUNTIMES_${target}_LIBUNWIND_INSTALL_LIBRARY OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXXABI_ENABLE_SHARED OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXXABI_ENABLE_STATIC_UNWINDER ON CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXXABI_INSTALL_LIBRARY OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXX_ENABLE_SHARED OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXX_ENABLE_STATIC_ABI_LIBRARY ON CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXX_ABI_VERSION 2 CACHE STRING "")
  set(RUNTIMES_${target}_LLVM_ENABLE_ASSERTIONS ON CACHE BOOL "")
  set(RUNTIMES_${target}_COMPILER_RT_INCLUDE_TESTS OFF CACHE BOOL "")
  set(RUNTIMES_${target}_COMPILER_RT_BUILD_XRAY OFF CACHE BOOL "")
  set(RUNTIMES_${target}_COMPILER_RT_BUILD_LIBFUZZER OFF CACHE BOOL "")
  set(RUNTIMES_${target}_COMPILER_RT_BUILD_PROFILE OFF CACHE BOOL "")
  if(build_sanitizers)
    set(RUNTIMES_${target}_SANITIZER_CXX_ABI "libc++" CACHE STRING "")
    set(RUNTIMES_${target}_SANITIZER_CXX_ABI_INTREE ON CACHE BOOL "")
  else()
    set(RUNTIMES_${target}_COMPILER_RT_BUILD_SANITIZERS OFF CACHE BOOL "")
    set(RUNTIMES_${target}_COMPILER_RT_SANITIZERS_TO_BUILD none CACHE STRING "")
  endif()
  set(RUNTIMES_${target}_LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING "")

  if(is_musl)
    set(RUNTIMES_${target}_LIBCXX_HAS_MUSL_LIBC ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_HAS_GCC_S_LIB OFF CACHE BOOL "")
  endif()

  # Use .build-id link.
  if(build_runtime)
    list(APPEND RUNTIME_BUILD_ID_LINK "${target}")
    set(RUNTIME_BUILD_ID_LINK ${RUNTIME_BUILD_ID_LINK} PARENT_SCOPE)
  endif()
endfunction()

# Linux & glibc
foreach(target aarch64-linux-gnu;;x86_64-linux-gnu;powerpc64le-linux-gnu)
  configure(${target} FALSE "Linux" ${target} FALSE TRUE)
endforeach()
configure(armv7-unknown-linux-gnueabihf FALSE "Linux" arm-linux-gnueabihf FALSE TRUE)
configure(i686-linux-gnu FALSE "Linux" i686-linux-gnu FALSE FALSE)

# Linux & musl
# foreach(target aarch64-linux-musl;i686-linux-musl;x86_64-linux-musl)
#   configure(${target} TRUE "Linux" ${target} FALSE)
# endforeach()
# configure(armv7-linux-musleabihf TRUE "Linux" arm-linux-musleabihf FALSE)

# Windows
foreach(target x86_64-w64-mingw32;i686-w64-mingw32)
  configure(${target} FALSE "Windows" ${target} FALSE FALSE)
endforeach()

# FreeBSD
set(target "x86_64-unknown-freebsd11.1")
configure(${target} FALSE "FreeBSD" ${target} FALSE TRUE)

# Setup darwin
set(target "x86_64-apple-darwin")
configure(${target} FALSE "Darwin" x86_64-apple-darwin14 FALSE FALSE)

set(BUILTINS_${target}_DARWIN_ios_ARCHS "" CACHE STRING "")
set(BUILTINS_${target}_DARWIN_iossim_ARCHS "" CACHE STRING "")
set(BUILTINS_${target}_DARWIN_osx_ARCHS x86_64;aarch64 CACHE STRING "")

set(RUNTIMES_${target}_COMPILER_RT_ENABLE_TVOS OFF CACHE BOOL "")
set(RUNTIMES_${target}_COMPILER_RT_ENABLE_WATCHOS OFF CACHE BOOL "")

# Setup components 
set(LLVM_BUILTIN_TARGETS "${BUILTIN_TARGETS}" CACHE STRING "")
set(LLVM_RUNTIME_TARGETS "${RUNTIME_TARGETS}" CACHE STRING "")
set(LLVM_RUNTIME_BUILD_ID_LINK_TARGETS "${RUNTIME_BUILD_ID_LINK}" CACHE STRING "")

# Setup toolchain.
set(LLVM_INSTALL_TOOLCHAIN_ONLY ON CACHE BOOL "")
set(LLVM_TOOLCHAIN_TOOLS 
  dsymutil
  llc
  llvm-ar
  llvm-cov
  llvm-cxxfilt
  llvm-dlltool
  llvm-dwarfdump
  llvm-dwp
  llvm-lib
  llvm-mt
  llvm-nm
  llvm-objcopy
  llvm-objdump
  llvm-profdata
  llvm-rc
  llvm-ranlib
  llvm-readelf
  llvm-readobj
  llvm-size
  llvm-strip
  llvm-symbolizer
  llvm-xray
  sancov
  CACHE STRING "")

set(LLVM_DISTRIBUTION_COMPONENTS
  clang
  lld
  LTO
  builtins
  runtimes
  ${LLVM_TOOLCHAIN_TOOLS}
  CACHE STRING "")