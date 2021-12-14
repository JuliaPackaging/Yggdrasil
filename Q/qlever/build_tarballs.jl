# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QLever"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ad-freiburg/qlever.git", "1d5503c65c604ce8fb5869da7f4f249a28be9dba"),
    DirectorySource("./bundled"),
]


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qlever/

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ../patches/win_grp_h.patch
fi

git submodule update --init --recursive

mkdir build && cd build
# -DSTXXL_TRY_COMPILE_HEADERS=ON ..
cmake -DCMAKE_BUILD_TYPE=Release -DLOGLEVEL=DEBUG -DUSE_PARALLEL=true -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DABSL_PROPAGATE_CXX_STD=ON -GNinja .. && ninja

make -j ${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# QLever depends on FOXXLL which only builds on 64-bit systems
# https://github.com/stxxl/foxxll/blob/a4a8aeee64743f845c5851e8b089965ea1c219d7/foxxll/common/types.hpp#L25
filter!(p -> nbits(p) != 32, platforms)

# Building against musl on Linux blocked by tlx dependency, issue #36 (https://github.com/tlx/tlx/issues/36)
 filter!(p -> !(Sys.islinux(p) && libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("ServerMain", :ServerMain),
    LibraryProduct("IndexBuilderMain", :IndexBuilderMain),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libuuid_jll", uuid="38a345b3-de98-5d2b-a5d3-14cd9215e700"))
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4"))
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"); compat="~1.76")
    Dependency(PackageSpec(name="ICU_jll", uuid="a51ab1cf-af8e-5615-a023-bc2c838bba6b"); compat = "~69.1")
    Dependency(PackageSpec(name="jemalloc_jll", uuid="454a8cc1-5e0e-5123-92d5-09b094f0e876"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1.0")

