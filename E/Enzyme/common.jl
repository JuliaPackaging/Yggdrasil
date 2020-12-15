using BinaryBuilder, Pkg

name = "Enzyme"
repo = "https://github.com/wsmoses/Enzyme.git"

version = v"0.0.4"

# Collection of sources required to build attr
sources = [GitSource(repo, "f86dc1b68d1d29b95912ee260810f2806657240a")]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Bash recipe for building across all platforms
script = raw"""
cd Enzyme
# install_license LICENSE.TXT

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=RelWithDebInfo)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

# Tell CMake where LLVM is
CMAKE_FLAGS+=(-DLLVM_DIR="${prefix}/lib/cmake/llvm")

# Force linking against shared lib
CMAKE_FLAGS+=(-DLLVM_LINK_LLVM_DYLIB=ON)

# Build the library
CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)
cmake -B build -S enzyme -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["LLVMEnzyme-9", "LLVMEnzyme"], :libEnzyme),
]
