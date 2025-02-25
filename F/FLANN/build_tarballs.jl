# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FLANN"
version = v"1.9.2"

sources = [
    GitSource("https://github.com/flann-lib/flann.git", "c50f296b0b27e14667d272b37acc63f949b305c4"),
]

script = raw"""

cd $WORKSPACE/srcdir/flann

cmake \
    -B build \
    -DBUILD_C_BINDINGS=ON \
    -DBUILD_DOC=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_MATLAB_BINDINGS=OFF \
    -DBUILD_PYTHON_BINDINGS=OFF \
    -DBUILD_TESTS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=11 \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
    -G Ninja

cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct("libflann_cpp", :libflann_cpp),
    LibraryProduct("libflann", :libflann)
]

dependencies = Dependency[
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency("CompilerSupportLibraries_jll", platforms = filter(!Sys.isbsd, platforms)),
    Dependency("LLVMOpenMP_jll", platforms = filter(Sys.isbsd, platforms)),

    Dependency("Lz4_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat = "1.6"
)
