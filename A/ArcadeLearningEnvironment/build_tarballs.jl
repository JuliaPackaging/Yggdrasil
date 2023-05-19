# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ArcadeLearningEnvironment"
version_actual = v"0.6.1"
version = v"0.6.2" # Fake version number for Julia 1.6 compat bound

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mgbellemare/Arcade-Learning-Environment.git", "5e3c3c17be85c427802e529b432b8aad2e7fa82c"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Arcade-Learning-Environment/
atomic_patch -p1 ../patches/fix-dlext-macos.patch
atomic_patch -p1 ../patches/cmake-install-for-windows.patch
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_SDL=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_CPP_LIB=OFF \
    -DBUILD_CLI=OFF \
    -DCMAKE_CXX_FLAGS="-I${includedir}" \
    -DCMAKE_SHARED_LINKER_FLAGS_INIT="-L${libdir}" \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libale_c", :libale_c)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
