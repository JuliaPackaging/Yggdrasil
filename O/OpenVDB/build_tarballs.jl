# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenVDB"
version = v"8.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/AcademySoftwareFoundation/openvdb/archive/refs/tags/v$(version).tar.gz", "d2e77a0720db79e9c44830423bdb013c24a1cf50994dd61d570b6e0c3e0be699")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openvdb-*/
mkdir build && cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

#Disable platforms that we don't have oneTBB for
filter!(p -> arch(p) ∉ ("armv6l", "armv7l"), platforms)
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libopenvdb", :libopenvdb),
    ExecutableProduct("vdb_print", :vdb_print)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"; compat="=1.76.0")
    Dependency(PackageSpec(name="oneTBB_jll", uuid="1317d2d5-d96f-522e-a858-c73665f53c3e"))
    Dependency(PackageSpec(name="Blosc_jll", uuid="0b7ba130-8d10-5ba8-a3d6-c5182647fed9"))
    Dependency("jemalloc_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
#min gcc version in top level CMakeLists.txt is set at 6.3.x, so bump up to 7
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7")
