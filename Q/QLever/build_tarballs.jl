# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QLever"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ad-freiburg/qlever.git", "facaf302ff922456c6b5c3eb6abb4f0dc68dd19f"),
    DirectorySource("./bundled"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qlever/

atomic_patch -p1 ../patches/cmake_fixes.patch

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ../patches/win_grp_h.patch
elif [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Work around the error: 'value' is unavailable: introduced in macOS 10.14 issue
    export CXXFLAGS="-mmacosx-version-min=10.15"
    # ...and install a newer SDK which supports `std::filesystem`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi    

git submodule update --init --recursive

mkdir build && cd build

export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=yes
export PKG_CONFIG_ALLOW_SYSTEM_LIBS=yes

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DUSE_PARALLEL=true)
CMAKE_FLAGS+=(-DLOGLEVEL=DEBUG)
CMAKE_FLAGS+=(-GNinja)
# CMAKE_FLAGS+=(-DANTLR_INCLUDE_DIR="${includedir}/antlr4-runtime")
CMAKE_FLAGS+=(-DGTEST_INCLUDE_DIR="${includedir}/gtest")
CMAKE_FLAGS+=(-DABSL_LOCAL_GOOGLETEST_DIR="${includedir}/gtest")
CMAKE_FLAGS+=(-DABSL_USE_EXTERNAL_GOOGLETEST=ON)
CMAKE_FLAGS+=(-DABSL_FIND_GOOGLETEST=ON)
CMAKE_FLAGS+=(-DABSL_PROPAGATE_CXX_STD=ON)
CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-pthread")
CMAKE_FLAGS+=(-DADDITIONAL_COMPILER_FLAGS=-Werror)

cmake ${CMAKE_FLAGS[@]} .. && ninja

cp CreatePatternsMain \
     IndexBuilderMain \
     TurtleParserMain \
     VocabularyMergerMain \
     PermutationExporterMain \
     PrefixHeuristicEvaluatorMain \
     ${libdir}

cp ServerMain \
     SparqlEngineMain \
     WriteIndexListsMain \
     ${libdir}

cd ../

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# QLever depends on FOXXLL which only builds on 64-bit systems
# https://github.com/stxxl/foxxll/blob/a4a8aeee64743f845c5851e8b089965ea1c219d7/foxxll/common/types.hpp#L25
filter!(p -> nbits(p) != 32, platforms)

# Building against musl on Linux blocked by tlx dependency (https://github.com/tlx/tlx/issues/36)
filter!(p -> !(Sys.islinux(p) && libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("CreatePatternsMain", :CreatePatternsMain),    
    LibraryProduct("IndexBuilderMain", :IndexBuilderMain),
    LibraryProduct("PermutationExporterMain", :PermutationExporterMain),
    LibraryProduct("PrefixHeuristicEvaluatorMain", :PrefixHeuristicEvaluatorMain),
    LibraryProduct("ServerMain", :ServerMain),
    LibraryProduct("SparqlEngineMain", :SparqlEngineMain),
    LibraryProduct("TurtleParserMain", :TurtleParserMain),
    LibraryProduct("VocabularyMergerMain", :PrefixHeuristicEvaluatorMain),
    LibraryProduct("WriteIndexListsMain", :WriteIndexListsMain),    
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libuuid_jll", uuid="38a345b3-de98-5d2b-a5d3-14cd9215e700")),
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4")),
    Dependency(PackageSpec(; name = "boost_jll",  uuid = "...", url = "https://github.com/jeremiahpslewis/boost_jll.jl.git")),
    Dependency(PackageSpec(name="ICU_jll", uuid="a51ab1cf-af8e-5615-a023-bc2c838bba6b"); compat = "~69.1"),
    Dependency(PackageSpec(name="jemalloc_jll", uuid="454a8cc1-5e0e-5123-92d5-09b094f0e876")),
    Dependency(PackageSpec(name="LibUnwind_jll", uuid="745a5e78-f969-53e9-954f-d19f2f74f4e3")),
    BuildDependency("GoogleTest_jll"),
    Dependency("Antlr4CppRuntime_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1.0")

