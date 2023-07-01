using BinaryBuilder, Pkg
using BinaryBuilderBase: default_host_platform

name = "libcifpp"
version = v"5.1.0"

# url = "https://github.com/PDB-REDO/libcifpp"
# description = "Library containing code to manipulate mmCIF and PDB files"

sources = [
    GitSource("https://github.com/PDB-REDO/libcifpp",
              "836aed6ea9a227b37e5b0d9cbcb1253f545d0778"),
    DirectorySource("./bundled"),
]

# TODO
# - the CCD (chemical components dictionary) normally gets downloaded
#   by default and saved under share/libcifpp/components.cif, but we
#   don't do this
#
#   This file is quite large (88MB gzipped, 380MB decompressed as of
#   July 2023). Therefore, download and installation of this file is
#   disabled for now, but not sure what functionality is impacted by
#   this. We should maybe think of a better way of sharing
#   components.cif between different packages that need it.
#   Ref: https://www.wwpdb.org/data/ccd

# Note: test suite (`make test`) is run if we are building for the
# build host platform BinaryBuilderBase.default_host_platform, which
# is the case for `$target == $MACHTYPE` inside the shell script.
#
# The tests only pass with the correct cxxabi (-cxx11), so we create a
# MACHTYPE_FULL variable to pass to the shell script which can there
# be matched against to bb_full_target.
#
# TODO: can we get the "libgfortran5" from default_host_platform?
#
# Convert x86_64-linux-musl-cxx11 -> x86_64-linux-musl-libgfortran5-cxx11
const M = split(triplet(default_host_platform), "-")
const MACHTYPE_FULL = join((M[1:3]..., "libgfortran5", M[4:end]...), "-")

script =
"""
MACHTYPE_FULL=$MACHTYPE_FULL
""" * raw"""
cd $WORKSPACE/srcdir/libcifpp*/

# mingw doesn't have ioctl
atomic_patch -p1 ../patches/mingw-no-ioctl.patch

mkdir build && cd build

CFG_TESTING="-DENABLE_TESTING=OFF"
if [[ "${bb_full_target}" == "${MACHTYPE_FULL}" ]]; then
    # build the tests if we are building for the build host platform
    CFG_TESTING="-DENABLE_TESTING=ON"
fi

# use gcc/g++ on apple
if [[ "${target}" == *-apple-darwin* ]]; then
    CMAKE_TARGET_TOOLCHAIN="$(dirname "${CMAKE_TARGET_TOOLCHAIN}")/target_${target}_gcc.cmake"
fi

# Set cmake cache vars because test programs can't be run during
# cross-compilation
#
# -DSTD_REGEX_RUNNING=0               # std::regex works
# -D_CXX_ATOMIC_BUILTIN_EXITCODE=0    # std::atomic works
# -D_CXX_ATOMIC_BUILTIN_EXITCODE__TRYRUN_OUTPUT=0
#
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_FOR_CCP4=OFF \
    -DCIFPP_DOWNLOAD_CCD=OFF \
    -DCIFPP_INSTALL_UPDATE_SCRIPT=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DSTD_REGEX_RUNNING=OFF \
    -D_CXX_ATOMIC_BUILTIN_EXITCODE=0 \
    -D_CXX_ATOMIC_BUILTIN_EXITCODE__TRYRUN_OUTPUT=0 \
    ${CFG_TESTING}

make -j${nproc}

if [[ "${bb_full_target}" == "${MACHTYPE_FULL}" ]]; then
    # run the tests on the build host platform
    make test
fi

make install

install_license ../LICENSE
"""

platforms = supported_platforms()
# Only FreeBSD uses clang in this build
platforms = expand_cxxstring_abis(platforms; skip=Sys.isfreebsd)

products = [
    LibraryProduct("libcifpp", :libcifpp),
]

dependencies = [
    BuildDependency("Eigen_jll"),
    Dependency("Zlib_jll"),
    # needed for make test, which we only run on the `default_host_platform`
    HostBuildDependency("boost_jll"; platforms=[default_host_platform]),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"9")
