using BinaryBuilder

name = "SwiftShader"

version = v"0.1.0" # there are no official versions yet
source = "https://github.com/google/swiftshader.git"
commit = "6c1ab2e3638260721c19b33017925f6deb9e30ac" # March 14th, 2023

sources = [
    GitSource(source, commit),
    DirectorySource("./patches"),
]

linux_script = raw"""
cd swiftshader

# Remove architecture-specific flags.
atomic_patch -p1 ${WORKSPACE}/srcdir/remove_march.patch

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Work around undefined `cinttypes` printing macros.
CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-D__STDC_FORMAT_MACROS")

# Do not enable the -Werror flag (builds fine without it).
CMAKE_FLAGS+=(-DSWIFTSHADER_WARNINGS_AS_ERRORS=FALSE)

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install

mv build/Linux/* ${libdir}

install_license LICENSE.txt
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    # TODO: Build on these platforms.
    # Platform("x86_64", "macos"),
    # Platform("x86_64", "windows"),
]

products = [
    LibraryProduct("libvulkan", :libvulkan),
    LibraryProduct("libvk_swiftshader", :libvk_swiftshader),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, linux_script, platforms, products, dependencies, preferred_gcc_version=v"11")
