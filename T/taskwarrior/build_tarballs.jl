using BinaryBuilder
using Pkg

name = "taskwarrior"
version = v"3.4.2"

sources = [
    GitSource("https://github.com/GothenburgBitFactory/taskwarrior", "48fb891c30fd7c572db3a4cff46e3435c75a1b6c"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/taskwarrior/

git submodule update --init

# Remove rustup check in corrosion's FindRust.cmake
pushd src/taskchampion-cpp/corrosion && \
    atomic_patch -p1 ../../../../patches/corrosion-remove-rustup-check.patch && \
    popd

# Needs at least CMake 3.22, BB image has 3.21 currently
apk del cmake

mkdir build
cd build

cmake \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DRust_COMPILER=$(which ${RUSTC}) \
    -DRust_CARGO_TARGET=${CARGO_BUILD_TARGET} \
    ..

make -j${nproc}
make install
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("task", :task),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Needs at least CMake 3.22, BB image has 3.21 currently
    HostBuildDependency("CMake_jll"),
    Dependency("Libuuid_jll"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.7", preferred_gcc_version=v"7")
