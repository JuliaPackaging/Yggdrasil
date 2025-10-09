using BinaryBuilder
using Pkg: PackageSpec
name    = "libfido2"
version = v"1.16.0"

sources = [
    ArchiveSource(
        "https://developers.yubico.com/libfido2/Releases/libfido2-1.16.0.tar.gz",
        "8c2b6fb279b5b42e9ac92ade71832e485852647b53607c43baaafbbcecea04e4",
        unpack_target="src",
    ),
    DirectorySource(string(@__DIR__,"/bundled")),
]

script = raw"""
cd ${WORKSPACE}/srcdir/src/libfido2-1.16.0
atomic_patch -p0 ../../patches/toplevel.patch
cd src
atomic_patch -p0 ../../../patches/src.patch
atomic_patch -p0 ../../../patches/fallthrough.patch
atomic_patch -p0 ../../../patches/hid_linux.patch

# Remove all problematic flags and macro redefs from all CMakeLists.txt
find . -type f -name 'CMakeLists.txt' | xargs sed -i -e 's/-Werror[^\ ]*//g' -e '/-Werror/d' -e '/Werror/d'
find . -type f -name 'CMakeLists.txt' -exec sed -i '/-Wno-cast-function-type/d' {} +
find . -type f -name 'CMakeLists.txt' -exec sed -i 's/-D_WIN32_WINNT=0x0600//g' {} +
echo 'add_compile_options(-Wno-error=deprecated-declarations)' >> CMakeLists.txt
cd ..

if [[ -f ${prefix}/bin/libcrypto.dll.a && ! -f ${prefix}/lib/libcrypto.dll.a ]]; then
  ln -sf ../bin/libcrypto.dll.a ${prefix}/lib/libcrypto.dll.a
fi
export LIBRARY_PATH="${prefix}/lib:${prefix}/bin:${LIBRARY_PATH}"
export PKG_CONFIG_PATH="${prefix}/lib/pkgconfig:${PKG_CONFIG_PATH}"
export CMAKE_PREFIX_PATH="${prefix}:${CMAKE_PREFIX_PATH}"

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_C_FLAGS="-Wno-error=deprecated-declarations" \
    -DOPENSSL_ROOT_DIR=${prefix} \
    -DOPENSSL_LIBRARIES=${prefix}/lib \
    -DBUILD_SHARED_LIBS=ON \
    -DWITH_LIBUDEV=OFF \
    -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TOOLS=OFF

cmake --build build --parallel ${nproc}
install_license LICENSE
cmake --install build
"""


platforms = supported_platforms()

products = [
    LibraryProduct("libfido2", :libfido2),
]

dependencies = [
  Dependency("libusb_jll"),
  Dependency("OpenSSL_jll"),
  Dependency("libcbor_jll"),
  #Dependency(
  #  PackageSpec(; 
  #    name="libcbor_jll",
  #    uuid="5d4dba4b-0609-5411-86b8-155d70b59700",
  #    path="/home/andre/.julia/dev/libcbor_jll"
  #  )
  #),
  Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
