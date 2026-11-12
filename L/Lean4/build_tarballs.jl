# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "Lean4"
version = v"4.35.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/leanprover/lean4.git", "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"),
    # The versions of CaDiCaL, mimalloc and leantar that the Lean build would otherwise download
    GitSource("https://github.com/arminbiere/cadical.git", "3ff42f04384489916f017acd6d5e7cbfa7257be7"),
    GitSource("https://github.com/microsoft/mimalloc.git", "acf2fdd329f9dc2a7ffe3f12a133fe7175e39378"),
    GitSource("https://github.com/digama0/leangz.git", "46485d0eca748ed2d2678e70d59949bbc602f32c"),
    # `LibUV_jll` is Julia's fork, which lacks parts of the upstream API that Lean uses.
    # This is the version that the official Lean binaries link statically.
    GitSource("https://github.com/libuv/libuv.git", "e9f29cb984231524e3931aa0ae2c5dae1a32884e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/lean4

# Lean needs a newer CMake than the one in the build image
apk del cmake

# Unused, and missing from the old glibc and musl we build against
sed -i '/#include <sys\/random.h>/d' src/runtime/io.cpp stage0/src/runtime/io.cpp

# `LEAN_STANDALONE` keeps the absolute paths of the build environment out of the flags that
# `leanc` uses to link Lean programs, so the libraries have to be listed by hand
COMMON_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DCCACHE=OFF
    -DLEAN_STANDALONE=ON
)
LEAN_LIBS="-lgmp -luv -lssl -lcrypto"

# Static libuv for the build host and for the target
cd ${WORKSPACE}/srcdir/libuv
LIBTOOLIZE=libtoolize sh autogen.sh
for build in host target; do
    mkdir build-${build} && cd build-${build}
    if [[ "${build}" == host ]]; then
        ../configure --prefix=${WORKSPACE}/libuv-host --build=${MACHTYPE} --host=${MACHTYPE} \
            --disable-shared --enable-static --with-pic CC="${HOSTCC}"
    else
        ../configure --prefix=${WORKSPACE}/libuv-target --build=${MACHTYPE} --host=${target} \
            --disable-shared --enable-static --with-pic
    fi
    make -j${nproc} install
    cd ..
done
cd ${WORKSPACE}/srcdir/lean4

# Stage 0 compiles the Lean sources of stage 1, so it has to run on the build host.
# The host compiler searches the target prefix by default, hence the explicit paths.
mkdir -p build-host/mimalloc/src
ln -s ${WORKSPACE}/srcdir/mimalloc build-host/mimalloc/src/mimalloc
(
    export PKG_CONFIG_PATH=${WORKSPACE}/libuv-host/lib/pkgconfig:${host_prefix}/lib/pkgconfig
    export PKG_CONFIG_SYSROOT_DIR=
    cmake -S stage0/src -B build-host/stage0 \
        -DSTAGE=0 \
        -DUSE_GITHASH=OFF \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
        -DGMP_INCLUDE_DIR=${host_includedir} \
        -DGMP_LIBRARIES=${host_libdir}/libgmp.so \
        -DOPENSSL_INCLUDE_DIR=${host_includedir} \
        -DOPENSSL_SSL_LIBRARY=${host_libdir}/libssl.so \
        -DOPENSSL_CRYPTO_LIBRARY=${host_libdir}/libcrypto.so \
        -DINSTALL_LEANTAR=OFF \
        -DSTRIP_BINARIES=OFF \
        -DLEAN_EXTRA_LINKER_FLAGS="-L${host_libdir} -L${WORKSPACE}/libuv-host/lib ${LEAN_LIBS}" \
        "${COMMON_FLAGS[@]}"
    make -C build-host/stage0 -j${nproc}
)
# Stage 1 loads the Lake plugin of stage 0 under the name it would have on the target
if [[ "${dlext}" != so ]]; then
    ln -s libLake_shared.so build-host/stage0/lib/lean/libLake_shared.${dlext}
fi

# CaDiCaL and `leantar` are installed next to `lean`; the Lean build would otherwise download
# them. The CaDiCaL makefile writes `cadical` two directories up.
make -C ${WORKSPACE}/srcdir/cadical -f ${PWD}/src/cadical.mk -j${nproc} CXX="${CXX}" CXXFLAGS="-DNCLOSEFROM"
(cd ${WORKSPACE}/srcdir/leangz && cargo build --locked --release --bin leantar)

mkdir -p build/mimalloc/src
ln -s ${WORKSPACE}/srcdir/mimalloc build/mimalloc/src/mimalloc
# Linking a Lean program statically needs libuv, so it is installed next to the Lean libraries
install -Dvm 644 ${WORKSPACE}/libuv-target/lib/libuv.a -t build/stage1/lib/lean

export PKG_CONFIG_PATH=${WORKSPACE}/libuv-target/lib/pkgconfig:${PKG_CONFIG_PATH}
if [[ "${target}" == *-apple-* ]]; then
    # Leave room for the audit to rewrite install names, as the Lean build does by default,
    # and keep the libraries above out of the stub libraries that do not use them
    LEAN_LIBS="${LEAN_LIBS} -headerpad_max_install_names -Wl,-dead_strip_dylibs"
fi
# The LLVM triple, which the Lean build can only find out by itself when the compiler is Clang
LEAN_PLATFORM_TARGET=$(echo ${target} | sed -e 's/-linux-/-unknown-linux-/' -e 's/^aarch64-apple/arm64-apple/' -e 's/-darwin.*/-darwin/')
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
    -DSTAGE1_PREV_STAGE=${PWD}/build-host/stage0 \
    -DSTAGE1_PREV_STAGE_CMAKE_EXECUTABLE_SUFFIX= \
    -DCADICAL=${WORKSPACE}/cadical \
    -DLEANTAR=${WORKSPACE}/srcdir/leangz/target/${rust_target}/release/leantar \
    -DLEANC_CC=cc \
    -DLEAN_PLATFORM_TARGET=${LEAN_PLATFORM_TARGET} \
    -DLEAN_EXTRA_LINKER_FLAGS="${LEAN_LIBS}" \
    -DINSTALL_LICENSE=OFF \
    "${COMMON_FLAGS[@]}"
make -C build -j${nproc}
make -C build install

install_license LICENSE LICENSES
for dep in cadical mimalloc leangz libuv; do
    install -Dvm 644 ${WORKSPACE}/srcdir/${dep}/LICENSE ${prefix}/share/licenses/${SRC_NAME}/LICENSE-${dep}
done
"""

# These are the platforms that Lean supports, plus musl, and without Windows, which needs ICU
# from the Windows SDK. The `.olean` files that stage 0 writes on the build host are only valid
# for 64-bit little-endian targets.
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]
platforms = expand_cxxstring_abis(platforms)
# `std::bit_cast` needs GCC 11, which only has the C++11 string ABI
filter!(p -> cxxstring_abi(p) != "cxx03", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("lean", :lean),
    ExecutableProduct("lake", :lake),
    ExecutableProduct("leanc", :leanc),
    ExecutableProduct("cadical", :cadical),
    ExecutableProduct("leantar", :leantar),
    LibraryProduct("libleanshared", :libleanshared, "lib/lean"; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("CMake_jll"),
    HostBuildDependency("GMP_jll"),
    HostBuildDependency("OpenSSL_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("GMP_jll"; compat="6.3.0"),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
]

# Lean and mimalloc need a newer libc++ than the one in the default macOS SDKs
sources, script = require_macos_sdk("14.5", sources, script; deployment_target="11.0")

# Build the tarballs, and possibly a `build.jl` as well.
# Lean requires GMP 6.3, which is the version that Julia 1.11 ships.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.11", compilers=[:c, :rust], preferred_gcc_version=v"11")
