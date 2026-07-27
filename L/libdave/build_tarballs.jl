using BinaryBuilder

name = "libdave"
version = v"1.0.0"

# libdave pins mlspp through its vcpkg overlay, keep the same commit here
sources = [
    GitSource("https://github.com/discord/libdave.git",
              "52cd56dc550f447fb354b3a06c9e2d2e2a4309c6"),
    GitSource("https://github.com/cisco/mlspp.git",
              "1cc50a124a3bc4e143a787ec934280dc70c1034d"),
    GitSource("https://github.com/nlohmann/json.git",
              "9cca280a4d0ccf0c08f47a99aa71d1b0e52f8d03"),
    DirectorySource("./bundled"),
]

script = raw"""
# -Werror breaks on warnings newer compilers introduce, and the two throwing
# std::get calls predate the default macOS deployment target (both are behind
# holds_alternative checks so get_if is equivalent)
pushd mlspp
atomic_patch -p1 ../patches/mlspp-remove-werror.patch
popd
pushd libdave
atomic_patch -p1 ../patches/libdave-remove-werror.patch
atomic_patch -p1 ../patches/libdave-variant-get-if.patch
popd

cmake -S json -B json/build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DJSON_BuildTests=OFF
cmake --build json/build --target install

# mlspp ships a bundled mpark variant behind this define, needed on Apple
# where the deployment target predates std::variant's throwing accessors
EXTRA_CXX_FLAGS=""
if [[ "${target}" == *-apple-* ]]; then
    EXTRA_CXX_FLAGS="-DVARIANT_COMPAT"
fi

# mingw OpenSSL_jll keeps import libs in lib64, but FindOpenSSL's MinGW
# branch only searches lib and ignores preset OPENSSL_*_LIBRARY variables
SSL_FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    mkdir -p ${prefix}/lib
    for lib in libcrypto libssl; do
        if [ -f ${prefix}/lib64/${lib}.dll.a ]; then
            ln -sf ${prefix}/lib64/${lib}.dll.a ${prefix}/lib/${lib}.dll.a
        fi
    done
    SSL_FLAGS=(-DOPENSSL_ROOT_DIR=${prefix})
fi

cmake -S mlspp -B mlspp/build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_CXX_FLAGS="${EXTRA_CXX_FLAGS}" \
    -DMLS_CXX_NAMESPACE=mlspp \
    -DDISABLE_GREASE=ON \
    -DTESTING=OFF \
    "${SSL_FLAGS[@]}"
cmake --build mlspp/build --target install -j${nproc}

cmake -S libdave/cpp -B libdave/cpp/build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="${EXTRA_CXX_FLAGS}" \
    -DBUILD_SHARED_LIBS=ON \
    -DTESTING=OFF \
    -DPERSISTENT_KEYS=OFF \
    "${SSL_FLAGS[@]}"
cmake --build libdave/cpp/build -j${nproc}
cmake --build libdave/cpp/build --target install

# the cmake rename to plain "dave" only happens off Windows
DAVE_LIB=dave
if [[ "${target}" == *-mingw* ]]; then
    DAVE_LIB=libdave
fi

# test helper exposing the MLS external sender that Discord's voice gateway
# normally provides, needed by downstream test suites since the C API alone
# cannot establish an MLS group
${CXX} -shared -fPIC -std=c++17 -O2 ${EXTRA_CXX_FLAGS} \
    -o ${libdir}/libdave_testutils.${dlext} \
    libdave/cpp/test/external_sender.cpp \
    libdave/cpp/test/capi/external_sender_wrapper.cpp \
    libdave/cpp/src/mls/parameters.cpp \
    libdave/cpp/src/mls/util.cpp \
    -Ilibdave/cpp/includes \
    -Ilibdave/cpp/src \
    -Ilibdave/cpp/test \
    -I${includedir} \
    -I${includedir}/mlspp \
    -L${libdir} \
    -L${prefix}/lib \
    -L${prefix}/lib64 \
    -l${DAVE_LIB} \
    -lmlspp \
    -lhpke \
    -ltls_syntax \
    -lbytes \
    -lcrypto

# drop build-time helpers so they do not end up in the tarball
if [[ "${target}" == *-mingw* ]]; then
    rm -f ${prefix}/lib/libcrypto.dll.a
    rm -f ${prefix}/lib/libssl.dll.a
fi
rm -f ${prefix}/lib/libmlspp.a
rm -f ${prefix}/lib/libhpke.a
rm -f ${prefix}/lib/libbytes.a
rm -f ${prefix}/lib/libtls_syntax.a
rm -f ${prefix}/lib/libmls_ds.a
rm -f ${prefix}/lib/libmls_vectors.a
rm -rf ${prefix}/share/mlspp
rm -rf ${prefix}/share/MLSPP
rm -rf ${prefix}/share/pkgconfig

install_license libdave/LICENSE
"""

platforms = supported_platforms()
# OpenSSL_jll 3.0.8 has no riscv64 build
filter!(p -> arch(p) != "riscv64", platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct(["libdave", "liblibdave"], :libdave),
    LibraryProduct("libdave_testutils", :libdave_testutils),
]

dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.8"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
