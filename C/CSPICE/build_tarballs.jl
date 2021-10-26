# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CSPICE"
version = v"66.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "http://naif.jpl.nasa.gov/pub/naif/toolkit//C/PC_Linux_GCC_64bit/packages/cspice.tar.Z",
        "93cd4fbce5818f8b7fecf3914c5756b8d41fd5bdaaeac1f4037b5a5410bc4768",
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd cspice
cp -r $WORKSPACE/srcdir/cmake .
mv cmake/CMakeLists.txt .
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/dskx02.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/subpnt.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/inquire.patch"
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/license/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcspice", :libcspice),
    LibraryProduct("libcsupport", :libcsupport),
    ExecutableProduct("brief", :brief),
    ExecutableProduct("chronos", :chronos),
    ExecutableProduct("ckbrief", :ckbrief),
    ExecutableProduct("commnt", :commnt),
    ExecutableProduct("dskbrief", :dskbrief),
    ExecutableProduct("dskexp", :dskexp),
    ExecutableProduct("frmdiff", :frmdiff),
    ExecutableProduct("inspekt", :inspekt),
    ExecutableProduct("mkdsk", :mkdsk),
    ExecutableProduct("mkspk", :mkspk),
    ExecutableProduct("msopck", :msopck),
    ExecutableProduct("spacit", :spacit),
    ExecutableProduct("spkdiff", :spkdiff),
    ExecutableProduct("spkmerge", :spkmerge),
    ExecutableProduct("tobin", :tobin),
    ExecutableProduct("toxfr", :toxfr),
    ExecutableProduct("version", :version),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
