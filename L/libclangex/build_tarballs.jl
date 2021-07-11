# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include("../../fancy_toys.jl")

name = "libclangex"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Gnimuc/libclangex.git", "2770c58ab8927b069a473bbfae8e94da01746266")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libclangex/
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
     -DLLVM_DIR=$prefix \
     -DCLANG_DIR=$prefix \
     -DLLVM_ASSERT_BUILD=false \
     -DCMAKE_BUILD_TYPE=Release \
     -DCMAKE_EXPORT_COMPILE_COMMANDS=true
make -j${nproc}
make install
install_license ../COPYRIGHT ../LICENSE-APACHE ../LICENSE-MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libclangex", :libclangex)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(get_addable_spec("LLVM_full_jll", v"11.0.1+3"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8")
