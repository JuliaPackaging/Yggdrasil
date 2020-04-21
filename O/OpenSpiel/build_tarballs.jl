# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenSpiel"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/findmyway/open_spiel/archive/v0.1.1.tar.gz", "8791ab9902aa46fd8263b79ea789f34d17e3a38dbc9e7ecbd46c5423922f0124"),
    ArchiveSource("https://github.com/findmyway/dds/archive/v0.1.0.tar.gz", "81070b8e96779b5b2303185642753013aa874bffbd58b9cc599204aee064292d"),
    ArchiveSource("https://github.com/findmyway/abseil-cpp/archive/v0.1.0.tar.gz", "7b612c1fed278250b5d1a4e29ddb410145b26a0e7c781c1ca4ac03d092179202"),
    ArchiveSource("https://github.com/findmyway/hanabi-learning-environment/archive/v0.1.0.tar.gz", "6126936fd13a95f8cadeacaa69dfb38a960eaf3bd588aacc8893a6e07e4791a3"),
    ArchiveSource("https://github.com/findmyway/project_acpc_server/archive/v0.1.0.tar.gz", "e29f969dd62ba354b7019cae3f7f1dbfbd9a744687ea4a8f7494c2bb1ee87382"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/armv7l/1.3/julia-1.3.1-linux-armv7l.tar.gz", "965c8fab2214f8ce1b3d449d088561a6de61be42543b48c3bbadaed5b02bf824"; unpack_target="julia-arm-linux-gnueabihf"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/x64/1.3/julia-1.3.1-linux-x86_64.tar.gz", "faa707c8343780a6fe5eaf13490355e8190acf8e2c189b9e7ecbddb0fa2643ad"; unpack_target="julia-x86_64-linux-gnu"),
    ArchiveSource("https://github.com/Gnimuc/JuliaBuilder/releases/download/v1.3.0/julia-1.3.0-x86_64-apple-darwin14.tar.gz", "f2e5359f03314656c06e2a0a28a497f62e78f027dbe7f5155a5710b4914439b1"; unpack_target="julia-x86_64-apple-darwin14"),
    ArchiveSource("https://github.com/Gnimuc/JuliaBuilder/releases/download/v1.3.0/julia-1.3.0-x86_64-w64-mingw32.tar.gz", "c7b2db68156150d0e882e98e39269301d7bf56660f4fc2e38ed2734a7a8d1551"; unpack_target="julia-x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""

case "$target" in
	arm-linux-gnueabihf|x86_64-linux-gnu)
        Julia_PREFIX=${WORKSPACE}/srcdir/julia-$target/julia-1.3.1
        ;;
    x86_64-apple-darwin14|x86_64-w64-mingw32)
        Julia_PREFIX=${WORKSPACE}/srcdir/julia-$target/juliabin
        ;;
esac

mv open_spiel-0.1.1 open_spiel
mv abseil-cpp-0.1.0/ open_spiel/open_spiel/abseil-cpp
mv dds-0.1.0 open_spiel/open_spiel/games/bridge/double_dummy_solver
mv hanabi-learning-environment-0.1.0 open_spiel/open_spiel/games/hanabi/hanabi-learning-environment
mv project_acpc_server-0.1.0 open_spiel/open_spiel/games/universal_poker/acpc

mkdir open_spiel/build
cd open_spiel/build
BUILD_WITH_PYTHON=OFF BUILD_WITH_JULIA=ON BUILD_WITH_HANABI=ON BUILD_WITH_ACPC=OFF cmake -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DJulia_PREFIX=$Julia_PREFIX -DCMAKE_PREFIX_PATH=$prefix/destdir/lib/cmake/JlCxx -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_FIND_ROOT_PATH=${prefix} ../open_spiel/
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/open_spiel/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(;cxxstring_abi=:cxx11)),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libspieljl", :libspieljl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8")
