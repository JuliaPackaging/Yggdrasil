using BinaryBuilder, Pkg

name = "binaryen"
version = v"1.0.0"

sources = [
    GitSource("https://github.com/WebAssembly/binaryen.git", "1fb1a2e2970472e9e93f9de94c8a2c674d0a0581"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/binaryen

atomic_patch -p1 ../patches/fix.patch

cmake . -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF \
-DBUILD_SHARED_LIBS=ON 

make -j${nproc}
make install
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
