# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

julia_versions = [v"1.6.3", v"1.7", v"1.8", v"1.9", v"1.10"]

name = "OpenSpiel"
version = v"1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/deepmind/open_spiel.git", "9e4559bd1d794aa0b6476013464b58329d8f2b51"), # v1.2.0
    GitSource("https://github.com/findmyway/dds.git", "091ea94358a4016d4fb6069dea5c452cdc98d0bd"), # v0.1.1
    GitSource("https://github.com/abseil/abseil-cpp.git", "b971ac5250ea8de900eae9f95e06548d14cd95fe"), # 20230125.2
    GitSource("https://github.com/findmyway/hanabi-learning-environment.git", "b31c973e3930804b9e27d1a20874e08d8643e533"), # v0.1.0
    GitSource("https://github.com/findmyway/project_acpc_server.git", "de5fb88ac597278c96875d3c163ce71cdfe7ea79"), # v0.1.0
]

# Bash recipe for building across all platforms
script = raw"""

mv abseil-cpp open_spiel/open_spiel/abseil-cpp
mv dds open_spiel/open_spiel/games/bridge/double_dummy_solver
mv hanabi-learning-environment open_spiel/open_spiel/games/hanabi/hanabi-learning-environment
mv project_acpc_server open_spiel/open_spiel/games/universal_poker/acpc

mkdir open_spiel/build
cd open_spiel/build
export OPEN_SPIEL_BUILD_WITH_JULIA=ON \
    OPEN_SPIEL_BUILD_WITH_PYTHON=OFF \
    OPEN_SPIEL_BUILD_WITH_HANABI=ON \
    OPEN_SPIEL_BUILD_WITH_ACPC=OFF

cmake \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix} \
    ../open_spiel/
    
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/open_spiel/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", julia_version=v)
    for v in julia_versions
]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libspieljl", :libspieljl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"; platforms=platforms),
    BuildDependency("libjulia_jll"; platforms=platforms)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9",
    julia_compat="1.6"
)
