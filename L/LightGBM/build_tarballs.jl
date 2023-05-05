# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LightGBM"
version = v"3.3.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/LightGBM.git", "ca035b2ee0c2be85832435917b1e0c8301d2e0e0"),
    GitSource("https://github.com/boostorg/compute.git", "36c89134d4013b2e5e45bc55656a18bd6141995a"),
    GitSource("https://gitlab.com/libeigen/eigen.git", "8ba1b0f41a7950dc3e1d4ed75859e36c73311235"),
    GitSource("https://github.com/lemire/fast_double_parser.git", "ace60646c02dc54c57f19d644e49a61e7e7758ec"),
    GitSource("https://github.com/fmtlib/fmt.git", "cc09f1a6798c085c325569ef466bcdcffdc266d4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cp -r ./compute/* ./LightGBM/external_libs/compute/
cp -r ./eigen/* ./LightGBM/external_libs/eigen/
cp -r ./fast_double_parser/* ./LightGBM/external_libs/fast_double_parser/
cp -r ./fmt/* ./LightGBM/external_libs/fmt/
cd LightGBM/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("lib_lightgbm", :lib_lightgbm),
    ExecutableProduct("lightgbm", :lightgbm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
