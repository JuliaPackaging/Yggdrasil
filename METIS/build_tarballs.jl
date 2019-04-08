using BinaryBuilder

name = "METIS"
version = v"5.1.0"

# Collection of sources required to build METIS
sources = [
    "http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz" =>
    "76faebe03f6c963127dbb73c13eab58c9a3faeae48779f049066a21c087c5db2",
    "./bundled",
]

# Bash recipe for building across all platforms
# Patches from https://github.com/msys2/MINGW-packages/tree/master/mingw-w64-metis
script = raw"""
cd $WORKSPACE/srcdir/metis-5.1.0/
if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/0001-mingw-w64-does-not-have-sys-resource-h.patch
    atomic_patch -p1 $WORKSPACE/srcdir/patches/0002-mingw-w64-do-not-use-reserved-double-underscored-names.patch
    atomic_patch -p1 $WORKSPACE/srcdir/patches/0003-WIN32-Install-RUNTIME-to-bin.patch
    atomic_patch -p1 $WORKSPACE/srcdir/patches/0004-Fix-GKLIB_PATH-default-for-out-of-tree-builds.patch
fi
mkdir -p build
cd build/
cmake $WORKSPACE/srcdir/metis-5.1.0/ \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain \
    -DCMAKE_VERBOSE_MAKEFILE=1 \
    -DGKLIB_PATH=$WORKSPACE/srcdir/metis-5.1.0/GKlib \
    -DSHARED=1
make -j${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libmetis", :libmetis)
]

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
