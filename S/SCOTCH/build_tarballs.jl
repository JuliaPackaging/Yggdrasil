# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SCOTCH"
version = v"7.0.11"

# Collection of sources required to complete build
sources = [
    # SCOTCH source code
    GitSource("https://gitlab.inria.fr/scotch/scotch", "626b88ce70edabb993bbee463f6c28ae2899af69"),
    # conda-forge patches for cross-building
    GitSource("https://github.com/conda-forge/scotch-feedstock", "73cc602e57759cd4a12823586aa46e29d7a7e6f7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/scotch

# Apply conda-forge patches
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0001-put-metis-headers-in-include-scotch.patch
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0002-fix-ptesmumps.h.patch
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0003-win-fix-ssize_t.patch
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0004-win-fix-context.c.patch
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0005-use-external-dummysizes.patch
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0006-win-fix-graph-match-scan.patch
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0007-allow-overriding-pthread_mutex_t-size.patch

################################################################################

# SCOTCH builds a helper program `dummysizes`, and runs it to extract sizes of datatypes.
# This does not work when cross-building.
# We build `dummysizes` ahead of time with the host compiler.

mkdir -p src/dummysizes/build-host
cd src/dummysizes
cp $WORKSPACE/srcdir/scotch-feedstock/recipe/CMakeLists-dummysizes.txt CMakeLists.txt

# First we need to find out `sizeof(pthread_mutex_t)` for the build platform
cat >find_mutex_size.c <<EOF
#include <pthread.h>
// Encode size as ASCII digits in a magic string
char info[] = {
    'I','N','F','O',':','s','i','z','e','[',
    ('0' + ((sizeof(pthread_mutex_t) / 10000) % 10)),
    ('0' + ((sizeof(pthread_mutex_t) /  1000) % 10)),
    ('0' + ((sizeof(pthread_mutex_t) /   100) % 10)),
    ('0' + ((sizeof(pthread_mutex_t) /    10) % 10)),
    ('0' + ((sizeof(pthread_mutex_t) /     1) % 10)),
    ']', '\0'
};
EOF
$CC -c find_mutex_size.c
mutex_size=$(
    strings find_mutex_size.o |
    grep 'INFO:size\[' |
    grep -o '\[[0-9]*\]' |
    tr -d '[]' |
    sed 's/^0*//'
)
echo "Found sizeof(pthread_mutex_t) = $mutex_size"

OPTIONS=(
    -DBUILD_LIBESMUMPS=OFF
    -DBUILD_LIBSCOTCHMETIS=OFF
    -DBUILD_PTSCOTCH=OFF
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN}
    -DENABLE_TESTS=OFF
    -DINTSIZE="32"
    -DMPI_THREAD_MULTIPLE=OFF
    -DSCOTCH_PATCHLEVEL=11
    -DSCOTCH_RELEASE=0
    -DSCOTCH_VERSION=7
    -DTHREADS=ON
)
cmake -B build-host ${OPTIONS[@]}
cmake --build build-host --parallel ${nproc}

################################################################################

# Now build SCOTCH

cd ${WORKSPACE}/srcdir/scotch

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

OPTIONS=(
    -DBUILD_LIBESMUMPS=ON
    -DBUILD_LIBSCOTCHMETIS=ON
    -DBUILD_PTSCOTCH=OFF
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_DUMMYSIZES=OFF
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=$prefix
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DENABLE_TESTS=OFF
    -DINSTALL_METIS_HEADERS=OFF
    -DINTSIZE="32"
    -DLIBSCOTCHERR=scotcherr
    -DMPI_THREAD_MULTIPLE=OFF
    -DTHREADS=ON
)

CFLAGS=$FLAGS cmake -B build ${OPTIONS[@]}
cmake --build build --parallel ${nproc}
cmake --install build

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
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"); compat="1.2.12"),
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"); compat="1.0.9"),
    Dependency(PackageSpec(name="XZ_jll", uuid="ffd25f8a-64ca-5728-b0f7-c24cf3aae800"); compat="5.8.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"9.1.0", julia_compat="1.6", preferred_llvm_version=v"13.0.1")
