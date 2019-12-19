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


function llvm_sources(;version = "v8.0.1", kwargs...)
    return [
        "https://github.com/llvm/llvm-project.git" =>
        llvm_tags[version],
        "./bundled",
    ]
end

# This is the shared buildscript across all versions.
# Thank God we're only building this for a single target.
function llvm_script(;version = v"8.0.1", llvm_build_type = "Release", kwargs...)
    """
    LLVM_MAJ_VER=$(version.major)
    LLVM_BUILD_TYPE=$(llvm_build_type)
    """ *
    raw"""
    apk add build-base python-dev linux-headers musl-dev zlib-dev

    # We need the XML2 and Zlib libraries in our LLVMBootstrap artifact,
    # and we also need them in target-prefixed directories, so they stick
    # around in `/opt/${target}/${target}/lib64` when mounted.
    mkdir -p ${prefix}/${target}/lib64
    # First, copy in the real files:
    cp -a $(realpath ${libdir}/libxml2.so) ${prefix}/${target}/lib64
    cp -a $(realpath ${libdir}/libz.so) ${prefix}/${target}/lib64

    # Then create the symlinks
    ln -s $(basename ${prefix}/${target}/lib64/libxml2.so.*) ${prefix}/${target}/lib64/libxml2.so
    ln -s $(basename ${prefix}/${target}/lib64/libz.so.*) ${prefix}/${target}/lib64/libz.so

    # Include ${prefix}/${target}/lib64 in our linker search path explicitly
    export LDFLAGS="${LDFLAGS} -L${prefix}/${target}/lib64"

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
    CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=${LLVM_BUILD_TYPE})

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
end

# The products that we will ensure are always built
function llvm_products(;kwargs...)
    return [
        # libraries
        LibraryProduct("libLLVM",  :libLLVM)
        LibraryProduct("libLTO",   :libLTO)
        LibraryProduct("libclang", :libclang)
        # tools
        ExecutableProduct("llvm-config", :llvm_config)
    ]
end

# Dependencies that must be installed before this package can be built
function llvm_dependencies(; kwargs...)
    return [
        "Zlib_jll",
        "XML2_jll",
    ]
end

function llvm_build_args(; kwargs...)
    return (
        llvm_sources(;kwargs...),
        llvm_script(;kwargs...),
        llvm_products(;kwargs...),
        llvm_dependencies(;kwargs...),
    )
end
