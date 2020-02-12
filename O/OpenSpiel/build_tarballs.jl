# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenSpiel"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    "https://github.com/findmyway/open_spiel/archive/v0.1.0.tar.gz" => "aa7bdff1fffb6dc0db580b2825cbc81b2a4a23ddf8aad6ce46dc397284444c09",
    "https://github.com/findmyway/dds/archive/v0.1.0.tar.gz" => "81070b8e96779b5b2303185642753013aa874bffbd58b9cc599204aee064292d",
    "https://github.com/findmyway/abseil-cpp/archive/v0.1.0.tar.gz" => "7b612c1fed278250b5d1a4e29ddb410145b26a0e7c781c1ca4ac03d092179202",
    "https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-linux-gnu.tar.gz" => "34b6e59acf8970a3327cf1603a8f90fa4da8e5ebf09e6624509ac39684a1835d",
    "https://github.com/findmyway/hanabi-learning-environment/archive/v0.1.0.tar.gz" => "6126936fd13a95f8cadeacaa69dfb38a960eaf3bd588aacc8893a6e07e4791a3",
]

# Bash recipe for building across all platforms
script = raw"""
mv open_spiel-0.1.0 open_spiel
mv abseil-cpp-0.1.0/ open_spiel/open_spiel/abseil-cpp
mv dds-0.1.0 open_spiel/open_spiel/games/bridge/double_dummy_solver
mv hanabi-learning-environment-0.1.0 open_spiel/open_spiel/games/hanabi/hanabi-learning-environment
mkdir julia
mv bin etc include lib share julia
cd julia
Julia_PREFIX=$PWD
mkdir ../open_spiel/build
cd ../open_spiel/build
BUILD_WITH_PYTHON=OFF BUILD_WITH_JULIA=ON BUILD_WITH_HANABI=ON cmake -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DJulia_PREFIX=$Julia_PREFIX -DJlCxx_DIR=$prefix/destdir/lib/cmake/JlCxx -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_FIND_ROOT_PATH=${prefix} ../open_spiel/
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
]

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
