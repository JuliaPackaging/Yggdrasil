using BinaryBuilder

name = "METIS"
version = v"5.1.4" # <-- This is a lie (upstream is 5.1.0/5.1.1): 5.1.4 = per-variant ELF symbol versions, so that consumers can pin it

# Collection of sources required to build METIS
sources = [
    # The official link to METIS 5.1.0 (http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz) is currently down.
    GitSource("https://github.com/amontoison/METIS.git", "e827ffed17d56a4ac1add9cc33342c453a06c209"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
# Patches from https://github.com/msys2/MINGW-packages/tree/master/mingw-w64-metis
script = raw"""
cd $WORKSPACE/srcdir/METIS
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
    # All four variants export the same symbol names (METIS_*, libmetis__*, gk_*).  On ELF
    # the dynamic linker resolves a name once per process, so two variants loaded together
    # (e.g. libmetis via MUMPS and libmetis_Int64_Real32 via SuperLU_DIST's Int64 library)
    # silently share one implementation and corrupt memory.  Give each variant its own
    # symbol version node: consumers linked against it carry versioned references that
    # cannot bind to another variant, while dlsym() by name keeps working (default
    # versions).  macOS (two-level namespace) and Windows (imports bound to a DLL name)
    # do not have this problem and have no symbol versioning, so ELF targets only.
    LINKER_FLAGS=""
    if [[ "${target}" != *-apple-* && "${target}" != *-mingw* ]]; then
        VERSION_NODE=$(echo "${1}" | tr '[:lower:]' '[:upper:]')
        echo "${VERSION_NODE} { global: *; };" > ${WORKSPACE}/srcdir/${1}.map
        LINKER_FLAGS="-Wl,--version-script=${WORKSPACE}/srcdir/${1}.map"
    fi
    cmake $WORKSPACE/srcdir/METIS/ \
        -DCMAKE_INSTALL_PREFIX=${METIS_PREFIX} \
        -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
        -DCMAKE_VERBOSE_MAKEFILE=1 \
        -DGKLIB_PATH=$WORKSPACE/srcdir/METIS/GKlib \
        -DSHARED=1 \
        -DCMAKE_C_FLAGS="-DIDXTYPEWIDTH=${2} -DREALTYPEWIDTH=${3}" \
        -DCMAKE_SHARED_LINKER_FLAGS="${LINKER_FLAGS}" \
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

# Build trigger: 3 (symbol versions per variant)
