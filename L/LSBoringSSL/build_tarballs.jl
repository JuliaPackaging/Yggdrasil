using BinaryBuilder

name = "LSBoringSSL"
version = v"2025.8.7" #Do not edit/update unless LSQUIC README has a new version requirement listed

sources = [
   GitSource("https://github.com/google/boringssl.git", 
              "e20e8486554098772673b55ea76bb003d0b330e5")
]

script = raw"""
cd  ${WORKSPACE}/srcdir/boringssl

mkdir build && cd build

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
   ..

make -j${nproc}

mkdir -p ${prefix}/lib
mkdir -p ${prefix}/include
cp crypto/libcrypto.a ssl/libssl.a ${prefix}/lib/
cp -r ../include/* ${prefix}/include/

mkdir -p ${prefix}/share/licenses/LSBoringSSL
cp ../LICENSE ${prefix}/share/licenses/LSBoringSSL/
"""

platforms = supported_platforms()

products = [
   LibraryProduct("libcrypto", :libcrypto),
   LibraryProduct("libssl", :libssl)
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               compilers=[:c, :go], julia_compat="1.6")