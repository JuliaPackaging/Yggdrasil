using BinaryBuilder

name = "METIS"
version = v"5.1.3" # <-- This is a lie, we're bumping to 5.1.1 to create a Julia v1.6+ release with experimental platforms

# Collection of sources required to build METIS
sources = [
    # The official link to METIS 5.1.0 (http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz) is currently down.
    GitSource("https://github.com/amontoison/METIS.git", "e827ffed17d56a4ac1add9cc33342c453a06c209"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
# Patches from https://github.com/msys2/MINGW-packages/tree/master/mingw-w64-metis
script = raw"""
cd $WORKSPACE/srcdir/metis-*
if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/0001-mingw-w64-does-not-have-sys-resource-h.patch
    atomic_patch -p1 $WORKSPACE/srcdir/patches/0002-mingw-w64-do-not-use-reserved-double-underscored-names.patch
    atomic_patch -p1 $WORKSPACE/srcdir/patches/0003-WIN32-Install-RUNTIME-to-bin.patch
    atomic_patch -p1 $WORKSPACE/srcdir/patches/0004-Fix-GKLIB_PATH-default-for-out-of-tree-builds.patch
fi
atomic_patch -p1 $WORKSPACE/srcdir/patches/005-add-ifndefs.patch
sed -i -e 's!add_library(metis.*!& \nset_target_properties(metis PROPERTIES OUTPUT_NAME "${BINARY_NAME}")!g' libmetis/CMakeLists.txt

mkdir -p build
cd build/
# {1} is binary name, {2} is inttype (32 or 64) and {3} is realtype (32 or 64), {4} is the prefix if necessary.
build_metis()
{
    METIS_PREFIX=${4:-${libdir}/metis/${1}}
    mkdir -p ${METIS_PREFIX}
    cmake $WORKSPACE/srcdir/metis-5.1.0/ \
        -DCMAKE_INSTALL_PREFIX=${METIS_PREFIX} \
        -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
        -DCMAKE_VERBOSE_MAKEFILE=1 \
        -DGKLIB_PATH=$WORKSPACE/srcdir/metis-5.1.0/GKlib \
        -DSHARED=1 \
        -DCMAKE_C_FLAGS="-DIDXTYPEWIDTH=${2} -DREALTYPEWIDTH=${3}" \
        -DBINARY_NAME="${1}"
    make -j${nproc} install
}

build_metis metis 32 32 $prefix
build_metis metis_Int32_Real64 32 64
build_metis metis_Int64_Real32 64 32
build_metis metis_Int64_Real64 64 64
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmetis", :libmetis),
    LibraryProduct("libmetis_Int32_Real64", :libmetis_Int32_Real64, 
        ["\$libdir/metis/metis_Int32_Real64/lib", "\$libdir/metis/metis_Int32_Real64/bin"]),
    LibraryProduct("libmetis_Int64_Real32", :libmetis_Int64_Real32, 
        ["\$libdir/metis/metis_Int64_Real32/lib", "\$libdir/metis/metis_Int64_Real32/bin"]),
    LibraryProduct("libmetis_Int64_Real64", :libmetis_Int64_Real64, 
        ["\$libdir/metis/metis_Int64_Real64/lib", "\$libdir/metis/metis_Int64_Real64/bin"])
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Build trigger: 2
