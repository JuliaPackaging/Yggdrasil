# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "casacorewrapper"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kiranshila/casascorewrapper.git", "f2a4d72a98e28534e36093f3c6e68ab41c96b1d4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/casascorewrapper/
mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCASACORE_ROOT_DIR=${prefix} \
    ..
make -j${nproc}
make install
"""

# Use the same platforms from casacore
platforms = supported_platforms(exclude=(platform) -> Sys.iswindows(platform) || Sys.isfreebsd(platform))
platforms = expand_cxxstring_abis(platforms)
# Expand libgfortran versions because we need to exclude some specific combinations
filter!(p -> libc(p) != "musl", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcasacorewrapper", :libcasacorewrapper)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="casacore_jll", uuid="72fd12c2-f19b-5d3c-931a-6bbe5223e3ce"); compat="=3.5.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
