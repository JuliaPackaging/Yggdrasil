# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CLFFT"
version = v"2.12.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/clMathLibraries/clFFT.git", "1e4833f060976971c4df4b54b1b9ad1620aaf1fb"),
    FileSource("https://patch-diff.githubusercontent.com/raw/clMathLibraries/clFFT/pull/245.patch",
               "b78e80258bd5dd41572dfad8f4c8fe3b0192d7d4f3bdaa85aae2d59f61184a88")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

install_license ./clFFT/LICENSE

patch ./clFFT/src/CMakeLists.txt 245.patch

cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_EXAMPLES=OFF -S ./clFFT/src -B ./clFFT/build
cmake --build ./clFFT/build --target install -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "macos")
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libclFFT", :libclfft)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="OpenCL_Headers_jll", version=v"2022.09.23")),
    Dependency("OpenCL_jll", compat="2022.09.23"),
    Dependency("FFTW_jll", compat="3.3.10"),
    Dependency("boost_jll", compat="=1.76.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6.1.0")
