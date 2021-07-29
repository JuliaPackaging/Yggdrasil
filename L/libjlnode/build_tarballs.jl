# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libjlnode"
version = v"14.17.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sunoru/jlnode.git", "1bb0c23e7f0200fdb9dd5bcd82e153d353264e37"),
    ArchiveSource("https://github.com/nodejs/node-addon-api/archive/refs/tags/4.0.0.tar.gz", "a61019de219cfbb4943b109fd1c56466c48dedbfcce10567f8e7826992be9c0d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

cd node-addon-api-*
export NAPI_INC=`pwd`

cd ../jlnode
mkdir build
cd build
cmake .. -G"Unix Makefiles" \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="`pwd`/Release" \
    -DCMAKE_JS_INC="${prefix}/include/node" \
    -DNAPI_INC="$NAPI_INC" \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build .
cmake --install .
install_license ../LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),

    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),

    # Platform("x86_64", "macos"),
    # Platform("aarch64", "macos"),

    # Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libjlnode", :libjlnode),
    FileProduct("lib/jlnode_addon.node", :jlnode_addon)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("libnode_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"6"
)
