### Instructions for adding a new version
#
# * add the version/commit SHA to `llvm_tags`.  Commit SHAs can be found
#   by viewing: https://github.com/llvm/llvm-project/releases
# * create the directory `0_RootFS/LLVMBootstrap@X`.  You can copy the
#   `build_tarballs.jl` file from `0_RootFS/LLVMBootstrap@X-1` and change the
#   version to build.  In order to reduce patches duplication, we want to use as
#   many symlinks as possible, so link to previously existing patches whenever
#   possible.  This shell command should be useful:
#
#      for p in ../../../LLVMBootstrap@X-1/bundled/patches/*.patch; do if [[ -L "${p}" ]]; then cp -a "${p}" .; else ln -s "${p}" .; fi; done
#
# * adapt the recipe as necessary, but try to make changes in a backward
#   compatible way.  If you introduce steps that are necessary only with
#   specific versions of LLVM, guard them with appropriate conditionals.  We may
#   need to use the same recipe to rebuild older versions of LLVM at a later
#   point and being able to rerun it as-is is extremely important
# * you only need to build the platform `x86_64-linux-musl`. To deploy the shard
#   and automatically update your BinaryBuilderBase's `Artifacts.toml`, use the
#   `--deploy` flag to the `build_tarballs.jl` script.  You can build & deploy
#   by running:
#
#      julia build_tarballs.jl --debug --verbose --deploy

include("./common.jl")

using BinaryBuilder
@eval BinaryBuilder.BinaryBuilderBase empty!(bootstrap_list)
@eval BinaryBuilder.BinaryBuilderBase push!(bootstrap_list, :rootfs, :platform_support)

llvm_tags = Dict(
    v"6.0.1" => "d359f2096850c68b708bc25a7baca4282945949f",
    v"7.1.0" => "4856a9330ee01d30e9e11b6c2f991662b4c04b07",
    v"8.0.1" => "19a71f6bdf2dddb10764939e7f0ec2b98dba76c9",
    v"9.0.1" => "c1a0a213378a458fbea1a5c77b315c7dce08fd05",
    v"10.0.1" => "ef32c611aa214dea855364efd7ba451ec5ec3f74",
    v"11.0.1" => "43ff75f2c3feef64f9d73328230d34dac8832a91",
    v"12.0.0" => "d28af7c654d8db0b68c175db5ce212d74fb5e9bc",
    v"13.0.1" => "75e33f71c2dae584b13a7d1186ae0a038ba98838",
    v"14.0.6" => "f28c006a5895fc0e329fe15fead81e37457cb1d1",
    v"15.0.7" => "8dfdcc7b7bf66834a761bd8de445840ef68e4d1a",
    v"16.0.6" => "7cbf1a2591520c2491aa35339f227775f4d3adf6",
    v"17.0.6" => "6009708b4367171ccdbf4b5905cb6a803753fe18",
    v"18.1.7" => "768118d1ad38bf13c545828f67bd6b474d61fc55",
)

function llvm_sources(;version = "v8.0.1", kwargs...)
    return [
        GitSource("https://github.com/llvm/llvm-project.git", llvm_tags[version]),
        DirectorySource("./bundled"; follow_symlinks=true),
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
    apk update
    apk add build-base python3 python3-dev linux-headers musl-dev zlib-dev

    # We need the XML2, iconv, Zlib libraries in our LLVMBootstrap artifact,
    # and we also need them in target-prefixed directories, so they stick
    # around in `/opt/${target}/${target}/lib64` when mounted.
    mkdir -p ${prefix}/${target}/lib64
    # First, copy in the real files:
    cp -a $(realpath ${libdir}/libxml2.so)  ${prefix}/${target}/lib64
    cp -a $(realpath ${libdir}/libiconv.so) ${prefix}/${target}/lib64
    cp -a $(realpath ${libdir}/libz.so)     ${prefix}/${target}/lib64

    # Then create the symlinks
    ln -s $(basename ${prefix}/${target}/lib64/libxml2.so.*) ${prefix}/${target}/lib64/libxml2.so
    ln -s $(basename ${prefix}/${target}/lib64/libxml2.so.*) ${prefix}/${target}/lib64/libxml2.so.2
    ln -s $(basename ${prefix}/${target}/lib64/libiconv.so.*) ${prefix}/${target}/lib64/libiconv.so
    ln -s $(basename ${prefix}/${target}/lib64/libiconv.so.*) ${prefix}/${target}/lib64/libiconv.so.2
    ln -s $(basename ${prefix}/${target}/lib64/libz.so.*) ${prefix}/${target}/lib64/libz.so
    ln -s $(basename ${prefix}/${target}/lib64/libz.so.*) ${prefix}/${target}/lib64/libz.so.1

    # Include ${prefix}/${target}/lib64 in our linker search path explicitly
    export LDFLAGS="-L${prefix}/${target}/lib64 -Wl,-rpath-link,${prefix}/${target}/lib64"
    # We will also need to run programs which require these libraries, so let them available to the dynamic loader
    export LD_LIBRARY_PATH="${prefix}/${target}/lib64"

    cd ${WORKSPACE}/srcdir/llvm-project
    # Apply all our patches
    if [ -d $WORKSPACE/srcdir/llvm_patches ]; then
    for f in $WORKSPACE/srcdir/llvm_patches/*.patch; do
        echo "Applying patch ${f}"
        atomic_patch -p1 ${f}
    done
    fi
    if [ -d $WORKSPACE/srcdir/clang_patches ]; then
    cd ${WORKSPACE}/srcdir/llvm-project/clang
    for f in $WORKSPACE/srcdir/clang_patches/*.patch; do
        echo "Applying patch ${f}"
        atomic_patch -p1 ${f}
    done
    fi
    if [ -d $WORKSPACE/srcdir/crt_patches ]; then
    cd ${WORKSPACE}/srcdir/llvm-project/compiler-rt
    for f in $WORKSPACE/srcdir/crt_patches/*.patch; do
        echo "Applying patch ${f}"
        atomic_patch -p1 ${f}
    done
    fi
    if [ -d $WORKSPACE/srcdir/libcxx_patches ]; then
    cd ${WORKSPACE}/srcdir/llvm-project/libcxx
    for f in $WORKSPACE/srcdir/libcxx_patches/*.patch; do
        echo "Applying patch ${f}"
        atomic_patch -p1 ${f}
    done
    fi
    # Patches from the monorepo
    if [ -d $WORKSPACE/srcdir/patches ]; then
    cd ${WORKSPACE}/srcdir/llvm-project
    for f in $WORKSPACE/srcdir/patches/*.patch; do
        echo "Applying patch ${f}"
        atomic_patch -p1 ${f}
    done
    fi

    # This value is really useful later
    cd ${WORKSPACE}/srcdir/llvm-project/llvm
    LLVM_SRCDIR=$(pwd)

    # Let's do the actual build within the `build` subdirectory
    mkdir build && cd build

    CMAKE_FLAGS=()
    # We build for all platforms, as we're going to use this to do cross-compilation
    CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=all)
    CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=${LLVM_BUILD_TYPE})

    # We want a lot of projects
    build_flang = version >= v"18"
    if build_flang
        # flang requires clang and mlir
        CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='clang;flang;lld;mlir;polly')
    else
        CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='clang;lld;polly')
    end

    # Build runtimes
    CMAKE_FLAGS+=(-DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi;libunwind')

    # We want a build with no bindings
    CMAKE_FLAGS+=(-DLLVM_BINDINGS_LIST=)

    # Turn off docs
    if build_flang
        # (We need examples to build flang)
        CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=OFF -DLLVM_INCLUDE_EXAMPLES=ON)
    else
        CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF)
    end

    # We want a shared library
    CMAKE_FLAGS+=(-DLLVM_BUILD_LLVM_DYLIB:BOOL=ON -DLLVM_LINK_LLVM_DYLIB:BOOL=ON)
    CMAKE_FLAGS+=("-DCMAKE_INSTALL_PREFIX=${prefix}")

    # Manually set the host triplet, as otherwise on some platforms it tries to guess using
    # `ld -v`, which is hilariously wrong. See llvm-project/llvm#49139, and note that setting
    # the triple to $target does not suffice. We also set a bunch of musl-related options here
    CMAKE_FLAGS+=("-DLLVM_HOST_TRIPLE=x86_64-alpine-linux-musl")
    CMAKE_FLAGS+=(-DLIBCXX_HAS_MUSL_LIBC=ON -DLIBCXX_HAS_GCC_S_LIB=OFF)
    CMAKE_FLAGS+=(-DCLANG_DEFAULT_CXX_STDLIB=libc++ -DCLANG_DEFAULT_LINKER=lld -DCLANG_DEFAULT_RTLIB=compiler-rt)
    CMAKE_FLAGS+=(-DLLVM_ENABLE_CXX1Y=ON -DLLVM_ENABLE_PIC=ON)

    # tell libcxx to use compiler-rt
    if [[ "${LLVM_MAJ_VER}" -ge "9" ]]; then
        CMAKE_FLAGS+=(-DLIBCXX_USE_COMPILER_RT=ON)
    fi

    # Tell compiler-rt to generate builtins for all the supported arches, and to use our unwinder
    CMAKE_FLAGS+=(-DCOMPILER_RT_DEFAULT_TARGET_ONLY=OFF)
    CMAKE_FLAGS+=(-DLIBCXXABI_USE_LLVM_UNWINDER=YES)

    # Sanitizers don't support musl
    # https://reviews.llvm.org/D63785
    CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_XRAY=OFF)
    CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_SANITIZERS=OFF)
    CMAKE_FLAGS+=(-DCOMPILER_RT_SANITIZERS_TO_BUILD=none)
    CMAKE_FLAGS+=(-DCOMPILER_RT_INCLUDE_TESTS=OFF)

    # Hint to find Zlib
    CMAKE_FLAGS+=(-DZLIB_ROOT="${prefix}")

    # Build!
    cmake ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
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
        Dependency("Zlib_jll"),
        Dependency("XML2_jll"),
	# transitive dependency libiconv
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
