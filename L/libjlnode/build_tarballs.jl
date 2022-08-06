# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libjlnode"
version = v"16.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sunoru/jlnode.git", "6f03cf76949a3cb0d755bf82999ab82aba8b3f20"),
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
    Dependency("libnode_jll", compat="16")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"6"
)
