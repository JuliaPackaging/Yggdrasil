# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SEAL_jll"
version = v"3.5.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/microsoft/SEAL/archive/v3.5.4.tar.gz",
                  "0c325c3e3d9b77be63ef866a7c73de861be46b99b61a22be60518d34865a1f37"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# Apply patches that fix some cross-compilation issues
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

cd SEAL-*

# The last three '-DSEAL_USE__*' flags are required to circumvent
# cross-compilation issues
if [[ "${target}" == *-darwin* ]]; then
  # C++17 is disabled on MacOS due to the environment being too old.
  cmake . \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DSEAL_BUILD_SEAL_C=ON \
    -DSEAL_USE___BUILTIN_CLZLL=OFF \
    -DSEAL_USE__ADDCARRY_U64=OFF \
    -DSEAL_USE__SUBBORROW_U64=OFF \
    -DSEAL_USE_CXX17=OFF
else
  cmake . \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DSEAL_BUILD_SEAL_C=ON \
    -DSEAL_USE___BUILTIN_CLZLL=OFF \
    -DSEAL_USE__ADDCARRY_U64=OFF \
    -DSEAL_USE__SUBBORROW_U64=OFF
fi
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:musl),
    MacOS(:x86_64),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    FreeBSD(:x86_64),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:aarch64, libc=:musl)
]

# Fix incompatibilities across the GCC 4/5 version boundary due to std::string,
# as suggested by the wizard
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsealc", :libsealc),
    LibraryProduct("libseal", :libseal)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0")
