include("./common.jl")

using BinaryBuilder
Core.eval(BinaryBuilder, :(bootstrap_list = [:rootfs, :platform_support]))

llvm_tags = Dict(
    v"6.0.1" => "d359f2096850c68b708bc25a7baca4282945949f",
    v"7.1.0" => "4856a9330ee01d30e9e11b6c2f991662b4c04b07",
    v"8.0.1" => "19a71f6bdf2dddb10764939e7f0ec2b98dba76c9",

    # This one doesn't work on musl yet.  :/
    #v"9.0.0" => "0399d5a9682b3cef71c653373e38890c63c4c365",
)

sources = [
    "https://github.com/llvm/llvm-project.git" =>
    llvm_tags[version],
    "./bundled",
]

# Since we kind of do this LLVM setup twice, this is the shared setup start:
script = "LLVM_MAJ_VER=$(version.major)\n" * raw"""
apk add build-base python-dev linux-headers musl-dev zlib-dev

# We're going to bake the XML2 and Zlib libraries into our artifact,
# we do so by collapsing the symlinks for the libraries we need:
for f in ${libdir}/*; do
    if [[ -h ${f} ]]; then
        cp -f $(realpath ${f}) ${f}
    fi
done

# Include ${libdir} in our linker search path explicitly
export LDFLAGS="${LDFLAGS} -L${libdir}"

# Patch compiler-rt
cd ${WORKSPACE}/srcdir/llvm-project
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/llvm${LLVM_MAJ_VER}_compiler_rt_musl.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/llvm${LLVM_MAJ_VER}_libcxx_musl.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/llvm${LLVM_MAJ_VER}_clang_musl_gcc_detector.patch

# This value is really useful later
cd ${WORKSPACE}/srcdir/llvm-project/llvm
LLVM_DIR=$(pwd)

# Let's do the actual build within the `build` subdirectory
mkdir build && cd build

CMAKE_FLAGS=()
# We build for all platforms, as we're going to use this to do cross-compilation
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=all)
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# We want a lot of projects
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='clang;compiler-rt;libcxx;libcxxabi;libunwind;polly')

# We want a build with no bindings
CMAKE_FLAGS+=(-DLLVM_BINDINGS_LIST=)

# Turn off docs
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF)

# We want a shared library
CMAKE_FLAGS+=(-DLLVM_BUILD_LLVM_DYLIB:BOOL=ON -DLLVM_LINK_LLVM_DYLIB:BOOL=ON)
CMAKE_FLAGS+=("-DCMAKE_INSTALL_PREFIX=${prefix}")

# Manually set the host triplet, as otherwise on some platforms it tries to guess using
# `ld -v`, which is hilariously wrong. We set a bunch of musl-related options here
CMAKE_FLAGS+=("-DLLVM_HOST_TRIPLE=${target}")
CMAKE_FLAGS+=(-DLIBCXX_HAS_MUSL_LIBC=ON -DLIBCXX_HAS_GCC_S_LIB=OFF)
CMAKE_FLAGS+=(-DCLANG_DEFAULT_CXX_STDLIB=libc++ -DCLANG_DEFAULT_LINKER=lld -DCLANG_DEFAULT_RTLIB=compiler-rt)
CMAKE_FLAGS+=(-DLLVM_ENABLE_CXX1Y=ON -DLLVM_ENABLE_PIC=ON)

# Tell compiler-rt to generate builtins for all the supported arches, and to use our unwinder
CMAKE_FLAGS+=(-DCOMPILER_RT_DEFAULT_TARGET_ONLY=OFF)
CMAKE_FLAGS+=(-DLIBCXXABI_USE_LLVM_UNWINDER=YES)

# Build!
cmake .. ${CMAKE_FLAGS[@]}
cmake -LA || true
make -j${nproc} VERBOSE=1

# Install!
make install -j${nproc} VERBOSE=1
"""

# The products that we will ensure are always built
products = [
    # libraries
    LibraryProduct("libLLVM",  :libLLVM)
    LibraryProduct("libLTO",   :libLTO)
    LibraryProduct("libclang", :libclang)
    # tools
    ExecutableProduct("llvm-config", :llvm_config)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Zlib_jll",
    "XML2_jll",
]
