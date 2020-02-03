# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenSpiel"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    "https://github.com/findmyway/open_spiel.git" => "2f9aa73e9c2fa8278209354b5b21bab8a93d35a0",
    "https://github.com/jblespiau/dds.git" => "06c1b31795ca2db2f268ea81a1029b03c8c37872",
    "https://github.com/abseil/abseil-cpp.git" => "0f86336b6939ea673cc1cbe29189286cae67d63a",
    "https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-linux-gnu.tar.gz" => "34b6e59acf8970a3327cf1603a8f90fa4da8e5ebf09e6624509ac39684a1835d"
]

# Bash recipe for building across all platforms
script = raw"""
mv abseil-cpp/ open_spiel/open_spiel/
mv dds open_spiel/open_spiel/games/bridge/double_dummy_solver
mkdir julia
mv bin etc include lib share julia
cd julia
Julia_PREFIX=$PWD
mkdir ../open_spiel/build
cd ../open_spiel/build
BUILD_WITH_PYTHON=OFF BUILD_WITH_JULIA=ON cmake -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DJulia_PREFIX=$Julia_PREFIX -DJlCxx_DIR=$prefix/destdir/lib/cmake/JlCxx -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_FIND_ROOT_PATH=${prefix} ../open_spiel/
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libspieljl", :libspieljl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "libcxxwrap_julia_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8")