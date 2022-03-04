# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Xerces"
version = v"3.2.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://apache.mirror.digionline.de//xerces/c/3/sources/xerces-c-3.2.3.tar.gz", "fb96fc49b1fb892d1e64e53a6ada8accf6f0e6d30ce0937956ec68d39bd72c7e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd xerces-c-3.2.3/
atomic_patch -p1 "${WORKSPACE}/srcdir/ThreadTest.patch"
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -Dnetwork:BOOL=OFF
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/xerces-c-3.2.3/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libxerces-c", :libxerces)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
