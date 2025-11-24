using BinaryBuilder

name = "SwiftShader"

version = v"0.1.1" # there are no official versions yet
source = "https://github.com/google/swiftshader.git"
commit = "6c1ab2e3638260721c19b33017925f6deb9e30ac" # March 14th, 2023

sources = [
    GitSource(source, commit),
    DirectorySource("./patches"),
]

script = raw"""
cd swiftshader

# Remove architecture-specific flags.
atomic_patch -p1 ${WORKSPACE}/srcdir/remove_march.patch

CXX_FLAGS=()
CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Work around undefined `cinttypes` printing macros.
CXX_FLAGS+="-D__STDC_FORMAT_MACROS"

# Do not enable the -Werror flag (builds fine without it).
CMAKE_FLAGS+=(-DSWIFTSHADER_WARNINGS_AS_ERRORS=FALSE)

# Don't build unit tests (they currently error the build because of yet unindentified libc++ issues).
CMAKE_FLAGS+=(-DSWIFTSHADER_BUILD_TESTS=FALSE)

# Handle Mac SDK <10.12 errors.
if [[ "${target}" == *-apple-* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.12
    CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBCXX=ON)
fi

if [[ "${target}" == *-mingw* ]]; then
    find . -type f -exec sed -i 's/include <Windows\.h>/include <windows\.h>/g' {} +
    CXX_FLAGS+=" -DHAVE_UNISTD"
fi

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]} -DCMAKE_CXX_FLAGS="${CXX_FLAGS}"
ninja -C build -j ${nproc} install

folderName=""
if [[ "${target}" == *-apple-* ]]; then
    echo "hello"
    folderName=Darwin
elif [[ "${target}" == *-linux-* ]]; then
    folderName=Linux
elif [[ "${target}" == *-mingw* ]]; then
    folderName=Windows
fi

mv -v build/$folderName/* ${libdir}

install_license LICENSE.txt
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    # TODO: Build on Windows.
    # Might want to take some inspiration from https://github.com/google/gfbuild-swiftshader/blob/master/build.sh
    # Platform("x86_64", "windows"),
]

platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libvulkan", :libvulkan),
    LibraryProduct("libvk_swiftshader", :libvk_swiftshader),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11")
