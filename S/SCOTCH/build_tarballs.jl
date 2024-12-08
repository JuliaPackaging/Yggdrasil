# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SCOTCH"
version = v"7.0.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.inria.fr/scotch/scotch", "e231061e53f3ad63d6cce19d983be2c6c4301749"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/scotch*
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/scotch.patch"

mkdir -p src/dummysizes/build-host
cd src/dummysizes/build-host
cp ${WORKSPACE}/srcdir/patches/CMakeLists-dummysizes.txt ../CMakeLists.txt

CC=${CC_BUILD} cmake .. \
    -DSCOTCH_VERSION=7 \
    -DSCOTCH_RELEASE=0 \
    -DSCOTCH_PATCHLEVEL=6 \
    -DBUILD_PTSCOTCH=OFF \
    -DCMAKE_BUILD_TYPE=Release

make -j${nproc}

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
    -DINSTALL_METIS_HEADERS=OFF \
    -DLIBSCOTCHERR=scotcherr \
    -DENABLE_TESTS=OFF

make -j${nproc}
make install

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
