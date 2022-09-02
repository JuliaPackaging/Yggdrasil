# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "libaom"
version = v"3.4.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://storage.googleapis.com/aom-releases/libaom-$(version).tar.gz", "bd754b58c3fa69f3ffd29da77de591bd9c26970e3b18537951336d6c0252e354")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libaom-*
mkdir build-dir
cd build-dir
CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DENABLE_TESTS=false -DBUILD_SHARED_LIBS=1"
if [[ "${target}" != "*86*" ]]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DAOM_TARGET_CPU=generic"
fi
cmake ${CMAKE_ARGS} ..
make -j${nproc}
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("aomenc", :aomenc),
    ExecutableProduct("aomdec", :aomdec),
    LibraryProduct(["libaom", "aom"], :libaom),
]

# Dependencies that must be installed before this package can be built
#
# YASM is recommended in the build instructions, but errors on apple platforms.
# Assembly only exists for x86 targets.
dependencies = [
    HostBuildDependency("YASM_jll"; platforms=filter(p->proc_family(p) == "intel" && !Sys.isapple(p), platforms)),
    HostBuildDependency("NASM_jll"; platforms=filter(p->proc_family(p) == "intel" && Sys.isapple(p), platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
