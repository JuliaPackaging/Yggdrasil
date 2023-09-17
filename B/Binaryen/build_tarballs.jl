using BinaryBuilder, Pkg

name = "Binaryen"
version = v"0.116.0"   # follows upstream's `version_116`

sources = [
    GitSource("https://github.com/WebAssembly/binaryen.git", "11dba9b1c2ad988500b329727f39f4d8786918c5"),
    DirectorySource("./bundled"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),

]

script = raw"""
cd $WORKSPACE/srcdir/binaryen

atomic_patch -p1 ../patches/fix.patch

mkdir build
cd build

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX10.15.sdk
    sed -i "s!/opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    export MACOSX_DEPLOYMENT_TARGET=10.15
fi

cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DBUILD_SHARED_LIBS=ON \
    ..

make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/binaryen/LICENSE
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libbinaryen", :libbinaryen)
    ExecutableProduct("wasm2js", :wasm2js)
    ExecutableProduct("wasm-opt", :wasmopt)
    ExecutableProduct("wasm-reduce", :wasmreduce)
    ExecutableProduct("wasm-merge", :wasmmerge)
    ExecutableProduct("wasm-split", :wasmsplit)
    ExecutableProduct("wasm-shell", :wasmshell)
    ExecutableProduct("wasm-metadce", :wasmmetadce)
    ExecutableProduct("wasm-dis", :wasmdis)
    ExecutableProduct("wasm-as", :wasmas)
    ExecutableProduct("wasm-ctor-eval", :wasmctoreval)
    ExecutableProduct("wasm-fuzz-types", :wasmfuzztypes)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
# Needed a c++17 compiler, 7 didn't work. 
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")
