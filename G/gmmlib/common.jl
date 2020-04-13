name = "gmmlib"

# Bash recipe for building across all platforms
script = raw"""
cd gmmlib
install_license LICENSE.md

CMAKE_FLAGS=()

if [[ ${target} == *musl* ]]; then
    # https://www.openwall.com/lists/musl/2018/09/11/2
    sed -i '/-fstack-protector/d' Source/GmmLib/Linux.cmake
fi

# Release build for best performance
# https://github.com/intel/gmmlib/issues/70
CMAKE_FLAGS+=(-DBUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

# Don't run tests
CMAKE_FLAGS+=(-DRUN_TEST_SUITE:Bool=OFF)

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libigdgmm", :libigdgmm),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]
