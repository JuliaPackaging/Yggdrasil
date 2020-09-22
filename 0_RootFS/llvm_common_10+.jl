include("./common.jl")

using BinaryBuilder
using BinaryBuilderBase
Core.eval(BinaryBuilderBase, :(bootstrap_list = [:rootfs, :platform_support, :glibc]))

llvm_tags = Dict(
    v"10.0.1" => "ef32c611aa214dea855364efd7ba451ec5ec3f74",
)

function llvm_sources(;version = "v8.0.1", kwargs...)
    return [
        GitSource("https://github.com/llvm/llvm-project.git", llvm_tags[version]),
        DirectorySource("./bundled"),
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
    apk add build-base python2-dev linux-headers musl-dev zlib-dev

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
    export LDFLAGS="${LDFLAGS} -L${prefix}/${target}/lib64"

    # Add it to LD_LIBRARY_PATH so that we can run `llvm-config` when needed for bootstrapping
    export LD_LIBRARY_PATH="${prefix}/${target}/lib64"

    cd ${WORKSPACE}/srcdir/llvm-project
    # Apply all our patches
    if [ -d $WORKSPACE/srcdir/patches ]; then
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

    CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=${LLVM_BUILD_TYPE})
    CMAKE_FLAGS+=("-DCMAKE_INSTALL_PREFIX=${prefix}")
    CMAKE_FLAGS+=("-DLLVM_HOST_TRIPLE=${target}")

    # Build!
    cmake -C ${WORKSPACE}/srcdir/bootstrap.cmake ${CMAKE_FLAGS[@]} ${LLVM_SRCDIR}
    cmake -LA || true

    make -j${nproc} VERBOSE=1 distribution

    # Install!
    make -j${nproc} VERBOSE=1 install-distribution
    # exit(1)
    """
end

# The products that we will ensure are always built
function llvm_products(;kwargs...)
    return [
        # libraries
        LibraryProduct("libLTO",   :libLTO)
        # tools
        ExecutableProduct("clang", :libclang)
        ExecutableProduct("llvm-config", :llvm_config)
    ]
end

# Dependencies that must be installed before this package can be built
function llvm_dependencies(; kwargs...)
    return [
        "Zlib_jll",
        "XML2_jll",
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
