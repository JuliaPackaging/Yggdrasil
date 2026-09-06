using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "Binaryen"
version = v"0.130.0"   # follows upstream's `version_130`

sources = [
    GitSource("https://github.com/WebAssembly/binaryen.git", "5d704ad52bc77a258e8fa3f9d34fcc5e8799c1c3"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/binaryen

atomic_patch -p1 ../patches/fix.patch

mkdir build
cd build

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

sources, script = require_macos_sdk("14.0", sources, script)

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"13")
