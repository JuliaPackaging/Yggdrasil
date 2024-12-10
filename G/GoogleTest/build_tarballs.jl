# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GoogleTest"
version = v"1.11.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/googletest.git", "e2239ee6043f73722e7aa812a459f54a28552929"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/googletest

if [[ "${target}" == *apple* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/no-known-features.patch"
fi

mkdir build && cd build
cmake -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_GMOCK=ON \
    -DCMAKE_CXX_STANDARD=11 \
    -Wno-dev \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libgtest_main", :libgtest_main),
    LibraryProduct("libgtest", :libgtest),
    LibraryProduct("libgmock_main", :libgmock_main),
    LibraryProduct("libgmock", :libgmock),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version = v"5")
