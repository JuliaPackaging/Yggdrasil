# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ORTools"
version = v"9.7"

# Collection of sources required to build this package
sources = [
    GitSource("https://github.com/google/or-tools.git",
              "6fa02e157a5c91067b7d7b88629472b9ed461193"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/or-tools*
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/cmake_dependencies_CMakeLists.txt.patch"
mkdir build
cmake --version
cmake -S. -Bbuild \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_DEPS:BOOL=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_SAMPLES:BOOL=OFF \
    -DUSE_SCIP:BOOL=OFF \
    -DUSE_HIGHS:BOOL=OFF \
    -DUSE_COINOR:BOOL=OFF \
    -DUSE_GLPK:BOOL=OFF
cmake --build build
cmake --build build --target install
""" * "$(Base.julia_cmd()) -e 'using InteractiveUtils; versioninfo()'"

# TODO: generate with ProtoBuf.jl.
#     julia -e "using ProtoBuf; protojl()" 

platforms = [
    Platform("x86_64", "linux"),
    # Platform("aarch64", "linux"),  # Abseil uses -march for some files.
    Platform("x86_64", "macos"),
    # Platform("aarch64", "macos"),  # Abseil uses -march for some files.
    Platform("x86_64", "freebsd"),
    Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libortools", :libortools),
]

# Dependencies that must be installed before this package can be built
dependencies = [Dependency("ProtoBuf")]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"12", preferred_llvm_version=v"16", julia_compat="1.6")
