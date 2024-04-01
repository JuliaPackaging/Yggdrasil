# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GiNaC"
version = v"1.8.6"

# Collection of sources required to complete build
sources = [
    GitSource("git://www.ginac.de/ginac.git", "586309024f43e28dee484e231e88b85bc2d646bc")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir $WORKSPACE/srcdir/GiNaC-build
cd $WORKSPACE/srcdir/GiNaC-build

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    $WORKSPACE/srcdir/ginac/

cmake --build . -j${nproc}
cmake --build . -t install

install_license $WORKSPACE/srcdir/ginac*/COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libginac", :libginac),
    ExecutableProduct("viewgar", :viewgar),
    ExecutableProduct("ginsh", :ginsh)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CLN_jll", uuid="b3974076-79ef-58d3-b5c7-5ef926e97925"))
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a"))
    HostBuildDependency(PackageSpec(name="Bison_jll", uuid="0f48145f-aea8-549d-8864-7f251ac1e6d0"))
    HostBuildDependency(PackageSpec(name="flex_jll", uuid="48a596b8-cc7a-5e48-b182-65f75e8595d0"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
