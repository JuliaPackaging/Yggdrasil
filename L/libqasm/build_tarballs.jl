# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libqasm"
version = v"0.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/QuTech-Delft/libqasm.git", "1f317077e2f2462cafec8385666d6e996340d2e8")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p libqasm/build
cd libqasm/build/
rm /usr/share/cmake/Modules/Compiler/._*
rm /usr/share/cmake/Modules/CompilerId/._*
rm /usr/share/cmake/Modules/._*
git submodule init
git submodule update
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DLIBQASM_COMPAT=ON -DBUILD_SHARED_LIBS=ON -DLIBQASM_BUILD_PYTHON=OFF ..
export PATH=$PATH:/workspace/srcdir/libqasm/build/src/cqasm/tree-gen/:/workspace/srcdir/libqasm/build/src/cqasm/func-gen/
make -j
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libcqasm", :libcqasm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CMake_jll", uuid="3f4e10e2-61f2-5801-8945-23b9d642d0e6"))
    Dependency(PackageSpec(name="Bison_jll", uuid="0f48145f-aea8-549d-8864-7f251ac1e6d0"))
    Dependency(PackageSpec(name="flex_jll", uuid="48a596b8-cc7a-5e48-b182-65f75e8595d0"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
