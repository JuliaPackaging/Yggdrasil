# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ClangExtract"
version = v"0.1.0"

# Collection of sources required to build ClangExtract
sources = [
    GitSource("https://github.com/SUSE/clang-extract.git", "ac81bbb8f95e6409da2eeee8ef41cc9d7d970241"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/clang-extract

# Find all C++ source files
MAIN_SOURCES="Main.cpp"
INLINE_SOURCES="Inline.cpp"
LIB_SOURCES=$(find libcextract -name "*.cpp" | tr '\n' ' ')

# Set up compiler flags - use c++2a for GCC 9 C++20 support
export CXXFLAGS="-std=c++2a -O3 -fPIC"
export CXXFLAGS="${CXXFLAGS} -I${host_prefix}/include"
export CXXFLAGS="${CXXFLAGS} -Ilibcextract"
export CXXFLAGS="${CXXFLAGS} -D_GNU_SOURCE"
export CXXFLAGS="${CXXFLAGS} -DLLVM_VERSION_MAJOR=20"

# Add LLVM includes
LLVM_CXXFLAGS=$(${host_prefix}/bin/llvm-config --cxxflags 2>/dev/null || echo "")
export CXXFLAGS="${CXXFLAGS} ${LLVM_CXXFLAGS}"

# Set up linker flags
export LDFLAGS="-L${host_prefix}/lib -L${libdir}"
export LDFLAGS="${LDFLAGS} -lclang-cpp -lLLVM"
export LDFLAGS="${LDFLAGS} -lelf -lz -lzstd"
export LDFLAGS="${LDFLAGS} -lpthread -ldl"

# Use g++ from the target toolchain
export CXX="g++"

echo "Building libcextract static library..."
# First compile all library sources into object files
mkdir -p build_objs
for src in ${LIB_SOURCES}; do
    obj_file="build_objs/$(basename ${src%.cpp}.o)"
    echo "Compiling $src -> $obj_file"
    ${CXX} ${CXXFLAGS} -c $src -o $obj_file
done

# Create static library
echo "Creating static library..."
ar rcs libcextract.a build_objs/*.o

# Build clang-extract executable
echo "Building clang-extract..."
${CXX} ${CXXFLAGS} ${MAIN_SOURCES} libcextract.a ${LDFLAGS} -o clang-extract

# Build ce-inline executable
echo "Building ce-inline..."
${CXX} ${CXXFLAGS} ${INLINE_SOURCES} libcextract.a ${LDFLAGS} -o ce-inline

# Install binaries
install -Dm755 clang-extract ${bindir}/clang-extract
install -Dm755 ce-inline ${bindir}/ce-inline

# Install license
install_license LICENSE.TXT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Only build for platforms where we have LLVM available
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
filter!(p -> arch(p) != "riscv64", platforms)

# Expand for C++ string ABIs - use cxx11 for newer C++ standard
platforms = expand_cxxstring_abis(platforms)

# Filter to only cxx11 platforms which have newer C++ support
filter!(p -> cxxstring_abi(p) == "cxx11", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("clang-extract", :clang_extract),
    ExecutableProduct("ce-inline", :ce_inline),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Elfutils_jll"),  # Required for libelf.h in ElfCXX.cpp
    Dependency("Zlib_jll"),      # Required for zlib.h in ElfCXX.cpp
    Dependency("Zstd_jll"),      # Required for zstd.h in ElfCXX.cpp
    # Clang includes LLVM
    Dependency("Clang_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Use GCC 9 which has full C++20 support
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6",
               preferred_llvm_version=v"20",
               preferred_gcc_version=v"9")