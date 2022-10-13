# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "osmium"
version = v"1.14.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/osmcode/osmium-tool.git", "bec0d8c6a058140179fae009858790adc529ec3e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/osmium-tool

# Patch Windows feature flag
atomic_patch -p1 ../patches/fix_windows_flag.patch

mkdir build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install
"""


# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("osmium", :osmium)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libosmium_jll", uuid="7f0a2ee1-9b43-5740-ae82-b54233cf7071"))
    BuildDependency(PackageSpec(name="protozero_jll", uuid="e2028600-4f28-5e5c-ab86-957950af6e0a"))
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"); compat="=1.76.0")
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"); compat="1.0.8")
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="Lz4_jll", uuid="5ced341a-0733-55b8-9ab6-a4889d929147"))
    Dependency(PackageSpec(name="Expat_jll", uuid="2e619515-83b5-522b-bb60-26c02a35a201"); compat="2.2.10")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6.1.0")
