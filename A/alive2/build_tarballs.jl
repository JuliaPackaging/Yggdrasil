# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "alive2"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AliveToolkit/alive2.git", "674feb28ed550704c9e18af3953ca2d2e45862e5"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
apk add re2c
cd $WORKSPACE/srcdir/alive2
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p2 ${f}
done
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("alive", :alive)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="z3_jll", uuid="1bc4e1ec-7839-5212-8f2f-0d16b7bd09bc"))
    Dependency(PackageSpec(name="LLVM_jll", uuid="86de99a1-58d6-5da7-8064-bd56ce2e322c"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1.0")
