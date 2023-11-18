# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SCOTCH"
version = v"7.0.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.inria.fr/scotch/scotch", "82ec87f558f4acb7ccb69a079f531be380504c92"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/scotch*

# https://github.com/conda-forge/scotch-feedstock
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
  atomic_patch -p1 ${f}
done

# We don't want to break the ABI if we have a new release.
sed s/'set_target_properties(scotch PROPERTIES VERSION'/'#set_target_properties(scotch PROPERTIES VERSION'/ -i src/libscotch/CMakeLists.txt
sed s/'  ${SCOTCH_VERSION}.${SCOTCH_RELEASE}.${SCOTCH_PATCHLEVEL})'/'#  ${SCOTCH_VERSION}.${SCOTCH_RELEASE}.${SCOTCH_PATCHLEVEL})'/ -i src/libscotch/CMakeLists.txt

mkdir -p src/dummysizes/build-host
cd src/dummysizes/build-host
cp ${WORKSPACE}/srcdir/patches/CMakeLists-dummysizes.txt ../CMakeLists.txt

CC=${CC_BUILD} cmake .. \
    -DBUILD_PTSCOTCH=OFF \
    -DCMAKE_BUILD_TYPE=Release

# make -j${nproc}
make

cd ${WORKSPACE}/srcdir/scotch*
mkdir build
cd build

FLAGS=""
if [[ "${target}" == *linux* ]]; then
    FLAGS="-lrt"
fi
if [[ "${target}" == *linux-musl* ]]; then
    FLAGS="-lrt -D_GNU_SOURCE"
fi
if [[ "${target}" == *freebsd* ]]; then
    FLAGS="-Dcpu_set_t=cpuset_t -D__BSD_VISIBLE"
fi

CFLAGS=$FLAGS cmake .. \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DINTSIZE="32" \
    -DTHREADS=ON \
    -DMPI_THREAD_MULTIPLE=OFF \
    -DBUILD_PTSCOTCH=OFF \
    -DBUILD_LIBESMUMPS=ON \
    -DBUILD_LIBSCOTCHMETIS=ON \
    -DBUILD_DUMMYSIZES=OFF \
    -DINSTALL_METIS_HEADERS=OFF

# make -j${nproc}
make

# make install
if [[ "${target}" == *mingw* ]]; then
    rm bin/libptesmumps.dll
    rm lib/libptesmumps.dll.a
    cp bin/*.dll $libdir
    cp lib/*.dll.a $prefix/lib
else
    rm lib/libptesmumps.$dlext
    cp lib/*.${dlext} $libdir
fi
cd src/include
cp scotch.h scotchf.h esmumps.h $includedir

install_license ${WORKSPACE}/srcdir/scotch/LICENSE_en.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libscotch", :libscotch),
    LibraryProduct("libesmumps", :libesmumps),
    LibraryProduct("libscotcherr", :libscotcherr),
    LibraryProduct("libscotcherrexit", :libscotcherrexit),
    LibraryProduct("libscotchmetisv3", :libscotchmetisv3),
    LibraryProduct("libscotchmetisv5", :libscotchmetisv5)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"); compat="1.0.8"),
    Dependency(PackageSpec(name="XZ_jll", uuid="ffd25f8a-64ca-5728-b0f7-c24cf3aae800"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"9.1.0", julia_compat="1.6", preferred_llvm_version=v"13.0.1")
