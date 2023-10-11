# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using Pkg

name = "Dyninst"
version = v"12.3.0"

# Collection of sources required to build hwloc
sources = [
    GitSource("https://github.com/dyninst/dyninst", "334b6856e28fd34a698ad74aa277f1399a814183"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/dyninst

rm -f /usr/share/cmake/Modules/Compiler/._*.cmake

# Find newer versions of TBB which are installed in a different directory structure
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/tbb-version.patch"
# Handle missing enum constants
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/df_1_pie.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/dt_flags_1.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/em_amdgpu.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/r_x86_64_rex_gotpcrelx.patch"

# TODO: 
#     -DCMAKE_BUILD_TYPE=Release \

# set(CMAKE_SKIP_BUILD_RPATH FALSE)
# set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
# set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
# set(DYNINST_RPATH_DIRECTORIES "\$ORIGIN")

cmake -B build -S . \
    -DCMAKE_SKIP_BUILD_RPATH=OFF \
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=OFF \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF \
    \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DENABLE_STATIC_LIBS=NO \
    -DSTERILE_BUILD=ON \
    -DUSE_OpenMP=ON
cmake --build build --parallel ${nproc}
cmake --build build --parallel ${nproc} --target install

# echo $libdir
# ls -l $libdir/libcommon.so*
# file $libdir/libcommon.so
# ldd $libdir/libcommon.so
# $libdir/libcommon.so || true
# 
# ldd /workspace/destdir/lib/libboost_atomic.so.1.79.0 || true
# ldd /workspace/destdir/lib/libboost_chrono.so.1.79.0 || true
# ldd /workspace/destdir/lib/libboost_date_time.so.1.79.0 || true
# ldd /workspace/destdir/lib/libboost_filesystem.so.1.79.0 || true
# ldd /workspace/destdir/lib/libboost_thread.so.1.79.0 || true
# ldd /lib64/libpthread.so.0 || true
# ldd /workspace/destdir/lib/libboost_timer.so.1.79.0 || true
# ldd /workspace/destdir/lib/libboost_system.so.1.79.0 || true
# ldd /workspace/destdir/lib/libtbbmalloc_proxy.so.2 || true
# ldd /workspace/destdir/lib/libtbbmalloc.so.2 || true
# ldd /workspace/destdir/lib/libtbb.so.12 || true
# ldd /workspace/destdir/lib/libstdc++.so.6 || true
# ldd /lib64/libm.so.6 || true
# ldd /workspace/destdir/lib/libgomp.so.1 || true
# ldd /workspace/destdir/lib/libgcc_s.so.1 || true
# ldd /lib64/libc.so.6 || true
# ldd /lib64/librt.so.1 || true
# ldd /lib64/libdl.so.2 || true

cat >dlopen.c <<EOF
#include <dlfcn.h>
#include <stdio.h>
int main(int *argc, char *argv[]) {
  // void *ptr = dlopen(argv[1], RTLD_NOW);
  void *ptr = dlopen(argv[1], RTLD_LAZY | RTLD_DEEPBIND);
  printf("ptr=%p\n", ptr);
  return 0;
}
EOF
cc -o dlopen dlopen.c -ldl

./dlopen $libdir/libcommon.so
./dlopen $libdir/libdynC_API.so
./dlopen $libdir/libdynDwarf.so
./dlopen $libdir/libdynElf.so
./dlopen $libdir/libdyninstAPI.so
./dlopen $libdir/libdyninstAPI_RT.so
./dlopen $libdir/libinstructionAPI.so
./dlopen $libdir/libparseAPI.so
./dlopen $libdir/libpatchAPI.so
./dlopen $libdir/libpcontrol.so
./dlopen $libdir/libstackwalk.so
./dlopen $libdir/libsymLite.so
./dlopen $libdir/libsymtabAPI.so

#TODO
# exit 1
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# Binutils and Elfutils require Linux
# TODO: We should be able to build on Windows without Binutils and Elfutils
filter!(Sys.islinux, platforms)
# cmake fails with "unknown platform"
filter!(p -> arch(p) ∉ ["armv6l", "armv7l"], platforms)
# linking fails with "undefined reference to `_r_debug'"
# TODO: Would this be fixed by linking against `libdl`?
filter!(p -> libc(p) ≠ "musl", platforms)

# TODO: For debugging:
filter!(p -> arch(p) == "x86_64" && Sys.islinux(p) && libc(p) == "glibc" && cxxstring_abi(p) == "cxx11",  platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("parseThat", :parseThat),
    LibraryProduct("libcommon", :libcommon),
    LibraryProduct("libdynC_API", :libdynC_API),
    LibraryProduct("libdynDwarf", :libdynDwarf),
    LibraryProduct("libdynElf", :libdynElf),
    LibraryProduct("libdyninstAPI", :libdyninstAPI),
    LibraryProduct("libdyninstAPI_RT", :libdyninstAPI_RT),
    LibraryProduct("libinstructionAPI", :libinstructionAPI),
    LibraryProduct("libparseAPI", :libparseAPI),
    LibraryProduct("libpatchAPI", :libpatchAPI),
    LibraryProduct("libpcontrol", :libpcontrol),
    LibraryProduct("libstackwalk", :libstackwalk),
    LibraryProduct("libsymLite", :libsymLite),
    LibraryProduct("libsymtabAPI", :libsymtabAPI),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("CMake_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    # We need at least v2.41 of Binutils_jll to get an `-fPIC` version of `libiberty.a`
    Dependency("Binutils_jll"; compat="2.41"),
    # We require at least v0.186 of Elfutils
    Dependency("Elfutils_jll"; compat="0.189"),
    # We require at least v2019.7 of oneTBB
    Dependency("oneTBB_jll"; compat="2021.8.0"),
    # We require at least v1.70.0 of Boost
    Dependency("boost_jll"; compat="=1.79.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# The auditor fails, maybe the init functions of some of the libraries do something weird
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7", skip_audit=false)
